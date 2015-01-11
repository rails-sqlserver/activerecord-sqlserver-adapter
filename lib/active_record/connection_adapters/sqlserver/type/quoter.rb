module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Quoter

          attr_reader :value, :type

          def initialize(value, type = nil)
            @value = value
            @type = type
          end

          def to_s
            @value.to_s
          end
          alias_method :to_str, :to_s

          def ==(other)
            other == to_s || super
          end
          alias_method :eql?, :==

          def quote_ss_value
            type.quote_ss(value)
          end

        end
      end
    end
  end
end
