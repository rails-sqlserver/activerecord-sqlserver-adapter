module ActiveRecord
  module ConnectionAdapters
    module SQLServerActiveRecordExtensions
      
      def self.included(klass)
        klass.extend ClassMethods
        class << klass
          alias_method_chain :reset_column_information, :sqlserver_columns_cache_support
          alias_method_chain :add_order!, :sqlserver_unique_checking
        end
      end
      
      module ClassMethods
        
        def reset_column_information_with_sqlserver_columns_cache_support
          connection.instance_variable_set :@sqlserver_columns_cache, {}
          reset_column_information_without_sqlserver_columns_cache_support
        end
        
        private
        
        def add_order_with_sqlserver_unique_checking!(sql, order, scope = :auto)
          order_sql = ''
          add_order_without_sqlserver_unique_checking!(order_sql, order, scope)
          unless order_sql.blank?
            unique_order_hash = {}
            orders_and_dirs_set = connection.send(:orders_and_dirs_set,order_sql)
            unique_order_sql = orders_and_dirs_set.inject([]) do |array,order_dir|
              ord, dir = order_dir
              if unique_order_hash[ord]
                array
              else
                unique_order_hash[ord] = true
                array << "#{ord} #{dir}".strip
              end
            end.join(', ')
            sql << "ORDER BY #{unique_order_sql}"
          end
        end
        
      end
      
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::ConnectionAdapters::SQLServerActiveRecordExtensions
