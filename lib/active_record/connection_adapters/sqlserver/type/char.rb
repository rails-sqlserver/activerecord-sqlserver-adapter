module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Char < String

          def type
            :char
          end

          def type_cast_for_database(value)
            return if value.nil?
            return value if value.is_a?(Data)
            Data.new(super)
          end

          class Data

            def initialize(value)
              @value = value.to_s
            end

            def quoted
              "'#{Utils.quote_string(@value)}'"
            end

            def to_s
              @value
            end
            alias_method :to_str, :to_s

          end

        end
      end
    end
  end
end
