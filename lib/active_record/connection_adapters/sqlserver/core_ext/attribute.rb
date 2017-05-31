require 'active_record/attribute'

module ActiveRecord
  class Attribute

    SQLSERVER_DATE_TIME_TYPES = [
      Type::SQLServer::Date,
      Type::SQLServer::DateTime,
      Type::SQLServer::Time
    ].freeze

    prepend Module.new {
      def forgetting_assignment
        case type
        when *SQLSERVER_DATE_TIME_TYPES then with_value_from_database(value)
        else super
        end
      end
    }

  end
end
