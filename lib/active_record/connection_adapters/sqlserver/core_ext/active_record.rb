module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module CoreExt
        module ActiveRecord
          
          extend ActiveSupport::Concern
          
          included do
            class_attribute :coerced_sqlserver_date_columns, :coerced_sqlserver_time_columns
            self.coerced_sqlserver_date_columns = Set.new
            self.coerced_sqlserver_time_columns = Set.new
          end

          module ClassMethods
            
            def execute_procedure(proc_name, *variables)
              if connection.respond_to?(:execute_procedure)
                connection.execute_procedure(proc_name,*variables)
              else
                []
              end
            end

            def coerce_sqlserver_date(*attributes)
              self.coerced_sqlserver_date_columns += attributes.map(&:to_s)
            end

            def coerce_sqlserver_time(*attributes)
              self.coerced_sqlserver_time_columns += attributes.map(&:to_s)
            end

          end

        end
      end
    end
  end
end


ActiveRecord::Base.send :include, ActiveRecord::ConnectionAdapters::Sqlserver::CoreExt::ActiveRecord
