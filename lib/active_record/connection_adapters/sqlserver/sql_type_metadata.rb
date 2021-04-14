# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class TypeMetadata < DelegateClass(SqlTypeMetadata)
        undef to_yaml if method_defined?(:to_yaml)

        include Deduplicable

        attr_reader :sqlserver_options

        def initialize(type_metadata, sqlserver_options: nil)
          super(type_metadata)
          @sqlserver_options = sqlserver_options
        end

        def ==(other)
          other.is_a?(TypeMetadata) &&
            __getobj__ == other.__getobj__ &&
            sqlserver_options == other.sqlserver_options
        end
        alias eql? ==

        def hash
          TypeMetadata.hash ^
            __getobj__.hash ^
            sqlserver_options.hash
        end

        private

        def deduplicated
          __setobj__(__getobj__.deduplicate)
          super
        end
      end
    end
  end
end
