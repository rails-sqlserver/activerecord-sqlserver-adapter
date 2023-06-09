# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Data
          attr_reader :value, :type

          delegate :sub, to: :value

          def initialize(value, type)
            @value, @type = value, type
          end

          def quoted
            type.quoted(@value)
          end

          def to_s
            @value
          end
          alias_method :to_str, :to_s

          def inspect
            @value.inspect
          end

          def eql?(other)
            # Support comparing `Type::Char`, `Type::Varchar` and `VarcharMax` with strings.
            # This happens when we use enum with string columns.
            if other.is_a?(::String)
              return type.is_a?(ActiveRecord::ConnectionAdapters::SQLServer::Type::String) && value == other
            end

            self.class == other.class && value == other.value
          end
          alias :== :eql?
        end
      end
    end
  end
end
