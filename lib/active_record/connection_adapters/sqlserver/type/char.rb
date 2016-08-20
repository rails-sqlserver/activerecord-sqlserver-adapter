module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Char < String

          def type
            :char
          end

          def serialize(value)
            return if value.nil?
            return value if value.is_a?(Data)
            Data.new(super)
          end

          def sqlserver_type
            'char'.tap do |type|
              type << "(#{limit})" if limit
            end
          end

          class Data

            def initialize(value)
              @quoted_id = value.respond_to?(:quoted_id)
              @value = @quoted_id ? value.quoted_id : value.to_s
            end

            def quoted
              @quoted_id ? @value : "'#{Utils.quote_string(@value)}'"
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
