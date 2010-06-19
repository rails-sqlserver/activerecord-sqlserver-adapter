require 'active_record/version'

module ActiveRecord
  module ConnectionAdapters
    module SQLServerCoreExtensions
      
      
      module ActiveRecord

        def self.included(klass)
          klass.extend ClassMethods
          class << klass
            alias_method_chain :reset_column_information, :sqlserver_cache_support
          end
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
            write_inheritable_attribute :coerced_sqlserver_date_columns, Set.new(attributes.map(&:to_s))
          end

          def coerce_sqlserver_time(*attributes)
            write_inheritable_attribute :coerced_sqlserver_time_columns, Set.new(attributes.map(&:to_s))
          end

          def coerced_sqlserver_date_columns
            read_inheritable_attribute(:coerced_sqlserver_date_columns) || []
          end

          def coerced_sqlserver_time_columns
            read_inheritable_attribute(:coerced_sqlserver_time_columns) || []
          end

          def reset_column_information_with_sqlserver_cache_support
            connection.send(:initialize_sqlserver_caches) if connection.respond_to?(:sqlserver?)
            reset_column_information_without_sqlserver_cache_support
          end

        end
        
        module JoinAssociationChanges
          
          def self.included(klass)
            klass.class_eval do
              include InstanceMethods
              # alias_method_chain :aliased_table_name_for, :sqlserver_support
            end
          end

          module InstanceMethods

            protected

            # An exact copy, except this method has a Regexp escape on the quoted table name.
            def aliased_table_name_for_with_sqlserver_support(name,suffix=nil)
              if !parent.table_joins.blank? && parent.table_joins.to_s.downcase =~ %r{join(\s+\w+)?\s+#{Regexp.escape(active_record.connection.quote_table_name(name.downcase))}\son}i
                @join_dependency.table_aliases[name] += 1
              end
              unless @join_dependency.table_aliases[name].zero?
                # if the table name has been used, then use an alias
                name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}#{suffix}"
                table_index = @join_dependency.table_aliases[name]
                @join_dependency.table_aliases[name] += 1
                name = name[0..active_record.connection.table_alias_length-3] + "_#{table_index+1}" if table_index > 0
              else
                @join_dependency.table_aliases[name] += 1
              end
              name
            end

          end
          
        end
        
      end
      
      
    end
  end
end


ActiveRecord::Base.send :include, ActiveRecord::ConnectionAdapters::SQLServerCoreExtensions::ActiveRecord

if ActiveRecord::VERSION::MAJOR == 2 && ActiveRecord::VERSION::MINOR >= 3
  require 'active_record/associations'
  ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.send :include, ActiveRecord::ConnectionAdapters::SQLServerCoreExtensions::ActiveRecord::JoinAssociationChanges
end

