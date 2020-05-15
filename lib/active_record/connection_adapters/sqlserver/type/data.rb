# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Data
          attr_reader :value, :type

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
            self.class == other.class && self.value == other.value
          end
          alias :== :eql?
        end
      end
    end
  end
end
