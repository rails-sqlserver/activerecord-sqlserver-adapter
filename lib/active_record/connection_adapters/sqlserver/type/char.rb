# frozen_string_literal: true

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

            Data.new super, self
          end

          def sqlserver_type
            "char".yield_self do |type|
              type += "(#{limit})" if limit
              type
            end
          end

          def quoted(value)
            return value.quoted_id if value.respond_to?(:quoted_id)

            Utils.quote_string_single(value)
          end
        end
      end
    end
  end
end
