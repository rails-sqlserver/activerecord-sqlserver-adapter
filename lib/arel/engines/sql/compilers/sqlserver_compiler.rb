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
        relation.skipped ? select_sql_with_skipped : select_sql_without_skipped
      end
      
      def delete_sql
        build_query \
          "DELETE #{taken_clause if relation.taken.present?}".strip,
          "FROM #{relation.table_sql}",
          ("WHERE #{relation.wheres.collect(&:to_sql).join(' AND ')}" unless relation.wheres.blank? )
      end
      
      
      protected
      
      def taken_only?
        relation.taken.present? && relation.skipped.blank?
      end
      
      def taken_clause
        "TOP (#{relation.taken.to_i}) "
      end
      
      def single_distinct_select?
        relation.select_clauses.size == 1 && relation.select_clauses.first.include?('DISTINCT')
      end
      
      def select_sql_without_skipped(windowed=false)
        joins   = relation.joins(self)
        wheres  = relation.where_clauses
        groups  = relation.group_clauses
        havings = relation.having_clauses
        orders  = relation.order_clauses
        select_clause = windowed ? relation.select_clauses.map{ |sc| bare_select_clause(sc) }.join(', ') : 
          "SELECT #{taken_clause if taken_only?}#{relation.select_clauses.join(', ')}"
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
        elsif relation.join?
          
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
        quoted_primary_key = engine.quote_column_name(relation.primary_key)
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
      
      def bare_select_clause(sc)
        i = sc.strip.rindex(' ')
        i ? sc.from(i).strip : sc
      end
      
      def table_name_from_select_clause(sc)
        parts = bare_select_clause(sc).split('.')
        tn = parts.third ? parts.second : (parts.second ? parts.first : nil)
        tn ? tn.tr('[]','') : nil
      end

      def table_names_from_select_clauses
        relation.select_clauses.map{ |sc| table_name_from_select_clause(sc) }.compact.uniq
      end
      
    end
  end
end
