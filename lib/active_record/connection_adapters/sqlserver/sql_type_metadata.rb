# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class TypeMetadata < DelegateClass(SqlTypeMetadata)
        undef to_yaml if method_defined?(:to_yaml)

        include Deduplicable

        attr_reader :is_identity, :is_primary, :table_name, :ordinal_position

        def initialize(type_metadata, is_identity: nil, is_primary: nil, table_name: nil, ordinal_position: nil)
          super(type_metadata)
          @is_identity = is_identity
          @is_primary = is_primary
          @table_name = table_name
          @ordinal_position = ordinal_position
        end

        def ==(other)
          other.is_a?(TypeMetadata) &&
            __getobj__ == other.__getobj__ &&
            is_identity == other.is_identity &&
            is_primary == other.is_primary &&
            table_name == other.table_name &&
            ordinal_position == other.ordinal_position
        end
        alias_method :eql?, :==

        def hash
          [TypeMetadata, __getobj__, is_identity, is_primary, table_name, ordinal_position].hash
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
