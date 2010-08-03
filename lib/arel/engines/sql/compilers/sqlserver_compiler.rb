module Arel
  class Lock < Compound
    def initialize(relation, locked)
      super(relation)
      @locked = true == locked ? "WITH(HOLDLOCK, ROWLOCK)" : locked
    end
  end
end

module Arel
  module SqlCompiler
    class SQLServerCompiler < GenericCompiler
      
      def select_sql
        if complex_count_sql?
          select_sql_with_complex_count
        elsif relation.skipped
          select_sql_with_skipped
        else
          select_sql_without_skipped
        end
      end
      
      def delete_sql
        build_query \
          "DELETE #{taken_clause if relation.taken.present?}".strip,
          "FROM #{relation.table_sql}",
          ("WHERE #{relation.wheres.collect(&:to_sql).join(' AND ')}" unless relation.wheres.blank? )
      end
      
      
      protected
      
      def complex_count_sql?
        projections = relation.projections
        Count === projections.first && projections.size == 1 &&
          (relation.taken.present? || relation.wheres.present?) && relation.joins(self).blank?
      end
      
      def taken_only?
        relation.taken.present? && relation.skipped.blank?
      end
      
      def taken_clause
        "TOP (#{relation.taken.to_i}) "
      end
      
      def single_distinct_select?
        relation.select_clauses.size == 1 && relation.select_clauses.first.include?('DISTINCT')
      end
      
      def all_select_clauses_aliased?
        relation.select_clauses.all? do |sc|
          sc.split(',').all? { |c| c.include?(' AS ') }
        end
      end
      
      def select_sql_with_complex_count
        joins   = relation.joins(self)
        wheres  = relation.where_clauses
        groups  = relation.group_clauses
        havings = relation.having_clauses
        orders  = relation.order_clauses
        taken   = relation.taken.to_i
        skipped = relation.skipped.to_i
        top_clause = "TOP (#{taken+skipped}) " if relation.taken.present?
        build_query \
          "SELECT COUNT([count]) AS [count_id]",
          "FROM (",
            "SELECT #{top_clause}ROW_NUMBER() OVER (ORDER BY #{rowtable_order_clauses.join(', ')}) AS [rn],",
            "1 AS [count]",
            "FROM #{relation.from_clauses}",
            (locked unless locked.blank?),
            (joins unless joins.blank?),
            ("WHERE #{wheres.join(' AND ')}" unless wheres.blank?),
            ("GROUP BY #{groups.join(', ')}" unless groups.blank?),
            ("HAVING #{havings.join(' AND ')}" unless havings.blank?),
            ("ORDER BY #{orders.join(', ')}" unless orders.blank?),
          ") AS [_rnt]",
          "WHERE [_rnt].[rn] > #{relation.skipped.to_i}"
      end
      
      def select_sql_without_skipped(windowed=false)
        selects = relation.select_clauses
        joins   = relation.joins(self)
        wheres  = relation.where_clauses
        groups  = relation.group_clauses
        havings = relation.having_clauses
        orders  = relation.order_clauses
        select_clause = windowed ? selects.map{ |sc| select_clause_without_expression(sc) }.join(', ') : 
          "SELECT #{taken_clause if taken_only?}#{selects.join(', ')}"
        build_query(
          select_clause,
          "FROM #{relation.from_clauses}",
          (locked unless locked.blank?),
          (joins unless joins.blank?),
          ("WHERE #{wheres.join(' AND ')}" unless wheres.blank?),
          ("GROUP BY #{groups.join(', ')}" unless groups.blank?),
          ("HAVING #{havings.join(' AND ')}" unless havings.blank?),
          ("ORDER BY #{orders.join(', ')}" if orders.present? && !windowed))
      end
      
      def select_sql_with_skipped
        tc = taken_clause if relation.taken.present? && !single_distinct_select?
        build_query \
          "SELECT #{tc}#{rowtable_select_clauses.join(', ')}",
          "FROM (",
            "SELECT ROW_NUMBER() OVER (ORDER BY #{rowtable_order_clauses.join(', ')}) AS [rn],",
            select_sql_without_skipped(true),
          ") AS [_rnt]",
          "WHERE [_rnt].[rn] > #{relation.skipped.to_i}"
      end
      
      def rowtable_select_clauses
        if single_distinct_select?
          ::Array.wrap(relation.select_clauses.first.dup.tap do |sc|
            sc.sub! 'DISTINCT', "DISTINCT #{taken_clause if relation.taken.present?}".strip
            sc.sub! table_name_from_select_clause(sc), '_rnt'
            sc.strip!
          end)
        elsif relation.join? && all_select_clauses_aliased?
          relation.select_clauses.map do |sc|
            sc.split(',').map { |c| c.split(' AS ').last.strip  }.join(', ')
          end
        else
          relation.select_clauses.map do |sc|
            sc.gsub /\[#{relation.table.name}\]\./, '[_rnt].'
          end
        end
      end
      
      def rowtable_order_clauses
        orders = relation.order_clauses
        if orders.present?
          orders
        elsif relation.join?
          table_names_from_select_clauses.map { |tn| quote("#{tn}.#{pk_for_table(tn)}") }
        else
          [quote("#{relation.table.name}.#{relation.primary_key}")]
        end
      end
      
      def limited_update_conditions(conditions,taken)
        quoted_primary_key = engine.connection.quote_column_name(relation.primary_key)
        conditions = " #{conditions}".strip
        build_query \
          "WHERE #{quoted_primary_key} IN",
          "(SELECT #{taken_clause if relation.taken.present?}#{quoted_primary_key} FROM #{engine.connection.quote_table_name(relation.table.name)}#{conditions})"
      end
      
      def quote(value)
        engine.connection.quote_column_name(value)
      end
      
      def pk_for_table(table_name)
        engine.connection.primary_key(table_name)
      end
      
      def select_clause_without_expression(sc)
        sc.split(',').map do |c|
          c.strip!
          c.sub!(/^(COUNT|SUM|MAX|MIN|AVG)\s*(\((.*)\))?/,'\3')
          c.sub!(/^DISTINCT\s*/,'')
          c.sub!(/TOP\s*\(\d+\)\s*/i,'')
          c.strip
        end.join(', ')
      end
      
      def table_name_from_select_clause(sc)
        parts = select_clause_without_expression(sc).split('.')
        tn = parts.third ? parts.second : (parts.second ? parts.first : nil)
        tn ? tn.tr('[]','') : nil
      end

      def table_names_from_select_clauses
        relation.select_clauses.map do |sc|
          sc.split(',').map { table_name_from_select_clause(sc) }
        end.flatten.compact.uniq
      end
      
    end
  end
end
