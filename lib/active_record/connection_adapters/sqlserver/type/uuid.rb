# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Uuid < String
          ACCEPTABLE_UUID = %r{\A\{?([a-fA-F0-9]{4}-?){8}\}?\z}x

          alias_method :serialize, :deserialize

          def type
            :uuid
          end

          def sqlserver_type
            "uniqueidentifier"
          end

          def serialize(value)
            return unless value

            Data.new super, self
          end

          def cast(value)
            value.to_s[ACCEPTABLE_UUID, 0]
          end

          def quoted(value)
            Utils.quote_string_single(value) if value
          end
        end
      end
    end
  end
end
