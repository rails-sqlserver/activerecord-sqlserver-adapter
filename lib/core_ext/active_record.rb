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
        
      end
      
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::ConnectionAdapters::SQLServerActiveRecordExtensions
