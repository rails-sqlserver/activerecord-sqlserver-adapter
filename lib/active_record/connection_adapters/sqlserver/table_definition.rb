module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition
        def uuid(name, options = {})
          column(name, 'uniqueidentifier', options)
        end

        def primary_key(name, type = :primary_key, options = {})
          return super unless type == :uuid
          options[:default] = options.fetch(:default, 'NEWID()')
          options[:primary_key] = true
          column name, type, options
        end

        def column(name, type = nil, options = {})
          super
          self
        end
      end
    end
  end
end
