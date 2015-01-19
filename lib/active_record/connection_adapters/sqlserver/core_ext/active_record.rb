module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module ActiveRecord

          extend ActiveSupport::Concern

          module ClassMethods

            def execute_procedure(proc_name, *variables)
              if connection.respond_to?(:execute_procedure)
                connection.execute_procedure(proc_name, *variables)
              else
                []
              end
            end

          end

        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::ActiveRecord
