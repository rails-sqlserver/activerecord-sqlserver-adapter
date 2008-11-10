module ActiveRecord
  module ConnectionAdapters
    module SQLServerActiveRecordExtensions
      
      def self.included(klass)
        klass.extend ClassMethods
        class << klass
          alias_method_chain :reset_column_information, :sqlserver_columns_cache_support
        end
      end
      
      module ClassMethods
        
        def reset_column_information_with_sqlserver_columns_cache_support
          connection.instance_variable_set :@sqlserver_columns_cache, {}
          reset_column_information_without_sqlserver_columns_cache_support
        end
        
        private
        
        # Overwrite the ActiveRecord::Base method for SQL server.
        # GROUP BY is necessary for distinct orderings
        def construct_finder_sql_for_association_limiting(options, join_dependency)
          scope       = scope(:find)
          is_distinct = !options[:joins].blank? || include_eager_conditions?(options) || include_eager_order?(options)

          sql = "SELECT #{table_name}.#{connection.quote_column_name(primary_key)} FROM #{table_name} "

          if is_distinct
            sql << join_dependency.join_associations.collect(&:association_join).join
            # merge_joins isn't defined in 2.1.1, but appears in edge
            if defined?(merge_joins)
            # The next line may fail with a nil error under 2.1.1 or other non-edge rails versions - Use this instead: add_joins!(sql, options, scope)
             add_joins!(sql, options[:joins], scope)
            else
             add_joins!(sql, options, scope)
            end
          end

          add_conditions!(sql, options[:conditions], scope)
          add_group!(sql, options[:group], scope)

          if options[:order] && is_distinct
            if sql =~ /GROUP\s+BY/i
              sql << ", #{table_name}.#{connection.quote_column_name(primary_key)}"
            else
              sql << " GROUP BY #{table_name}.#{connection.quote_column_name(primary_key)}"
            end #if sql =~ /GROUP BY/i

            connection.add_order_by_for_association_limiting!(sql, options)
          else
            add_order!(sql, options[:order], scope)
          end

          add_limit!(sql, options, scope)

          return sanitize_sql(sql)
        end
        
      end
      
      
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::ConnectionAdapters::SQLServerActiveRecordExtensions
