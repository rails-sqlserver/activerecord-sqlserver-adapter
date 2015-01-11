module ActiveRecord
  module Type
    class Value

      module SQLServerBehavior

        extend ActiveSupport::Concern

        included do
          self.type_cast_from_ss_database = false
        end

        module ClassMethods

          def type_cast_from_ss_database
            @@type_cast_from_ss_database
          end

          def type_cast_from_ss_database=(boolean)
            @@type_cast_from_ss_database = !!boolean
          end

        end

        def type_cast_from_ss_database?
          self.class.type_cast_from_ss_database
        end

        def type_cast_from_database(value)
          type_cast_from_ss_database? ? super : value
        end

      end

      include SQLServerBehavior

    end
  end
end
