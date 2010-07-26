module Arel
  class Lock < Compound
    def initialize(relation, locked, &block)
      @relation = relation
      @locked   = locked.blank? ? "WITH(HOLDLOCK, ROWLOCK)" : locked
    end
  end
end

module Arel
  module SqlCompiler
    class SQLServerCompiler < GenericCompiler
      
      def select_sql
        skipped ? select_sql_with_skipped : select_sql_without_skipped
      end
      
      def delete_sql
        build_query \
          "DELETE #{taken_clause if taken.present?}".strip,
          "FROM #{table_sql}",
          ("WHERE #{wheres.collect(&:to_sql).join(' AND ')}" unless wheres.blank? )
      end
      
      
      protected
      
      def taken_only?
        taken.present? && skipped.blank?
      end
      
      def taken_clause
        "TOP (#{taken.to_i}) "
      end
      
      def single_distinct_select?
        select_clauses.size == 1 && select_clauses.first.include?('DISTINCT')
      end
      
      def select_sql_without_skipped(windowed=false)
        select_clause = windowed ? select_clauses.map{ |sc| bare_select_clause(sc) }.join(', ') : 
          "SELECT #{taken_clause if taken_only?}#{select_clauses.join(', ')}"
        build_query(
          select_clause,
          "FROM #{from_clauses}",
          (locked unless locked.blank?),
          (joins(self) unless joins(self).blank?),
          ("WHERE #{where_clauses.join(' AND ')}" unless wheres.blank?),
          ("GROUP BY #{group_clauses.join(', ')}" unless groupings.blank?),
          ("HAVING #{having_clauses.join(' AND ')}" unless havings.blank?),
          ("ORDER BY #{order_clauses.join(', ')}" if orders.present? && !windowed))
      end
      
      def select_sql_with_skipped
        tc = taken_clause if taken.present? && !single_distinct_select?
        build_query \
          "SELECT #{tc}#{rowtable_select_clauses.join(', ')}",
          "FROM (",
            "SELECT ROW_NUMBER() OVER (ORDER BY #{rowtable_order_clauses.join(', ')}) AS [rn],",
            select_sql_without_skipped(true),
          ") AS [_rnt]",
          "WHERE [_rnt].[rn] > #{skipped.to_i}"
      end
      
      def rowtable_select_clauses
        if single_distinct_select?
          ::Array.wrap(select_clauses.first.dup.tap do |sc|
            sc.sub! 'DISTINCT', "DISTINCT #{taken_clause if taken.present?}".strip
            sc.sub! table_name_from_select_clause(sc), '_rnt'
            sc.strip!
          end)
        elsif join?
          
        else
          select_clauses.map do |sc| 
            sc.gsub /\[#{table.name}\]\./, '[_rnt].'
          end
        end
      end
      
      def rowtable_order_clauses
        if order_clauses.present?
          order_clauses
        elsif join?
          table_names_from_select_clauses.map { |tn| quote("#{tn}.#{pk_for_table(tn)}") }
        else
          [quote("#{table.name}.#{primary_key}")]
        end
      end
      
      def limited_update_conditions(conditions,taken)
        quoted_primary_key = engine.quote_column_name(primary_key)
        conditions = " #{conditions}".strip
        build_query \
          "WHERE #{quoted_primary_key} IN",
          "(SELECT #{taken_clause if taken.present?}#{quoted_primary_key} FROM #{engine.connection.quote_table_name(table.name)}#{conditions})"
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
        select_clauses.map{ |sc| table_name_from_select_clause(sc) }.compact.uniq
      end
      
    end
  end
end
