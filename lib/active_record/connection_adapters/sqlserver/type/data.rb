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

        end
      end
    end
  end
end
