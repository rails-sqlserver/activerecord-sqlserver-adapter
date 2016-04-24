module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Char < String

          def type
            :char
          end

          class Data

            def initialize(value)
              @value = value.to_s
            end

            def quoted
              "'#{@value}'"
            end

          end

        end
      end
    end
  end
end
