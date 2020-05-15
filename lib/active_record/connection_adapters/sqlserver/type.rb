# frozen_string_literal: true

require "active_record/type"
# Behaviors
require "active_record/connection_adapters/sqlserver/type/data"
require "active_record/connection_adapters/sqlserver/type/time_value_fractional"
# Exact Numerics
require "active_record/connection_adapters/sqlserver/type/integer"
require "active_record/connection_adapters/sqlserver/type/big_integer"
require "active_record/connection_adapters/sqlserver/type/small_integer"
require "active_record/connection_adapters/sqlserver/type/tiny_integer"
require "active_record/connection_adapters/sqlserver/type/boolean"
require "active_record/connection_adapters/sqlserver/type/decimal"
require "active_record/connection_adapters/sqlserver/type/money"
require "active_record/connection_adapters/sqlserver/type/small_money"
# Approximate Numerics
require "active_record/connection_adapters/sqlserver/type/float"
require "active_record/connection_adapters/sqlserver/type/real"
# Date and Time
require "active_record/connection_adapters/sqlserver/type/date"
require "active_record/connection_adapters/sqlserver/type/datetime"
require "active_record/connection_adapters/sqlserver/type/datetime2"
require "active_record/connection_adapters/sqlserver/type/datetimeoffset"
require "active_record/connection_adapters/sqlserver/type/smalldatetime"
require "active_record/connection_adapters/sqlserver/type/time"
# Character Strings
require "active_record/connection_adapters/sqlserver/type/string"
require "active_record/connection_adapters/sqlserver/type/char"
require "active_record/connection_adapters/sqlserver/type/varchar"
require "active_record/connection_adapters/sqlserver/type/varchar_max"
require "active_record/connection_adapters/sqlserver/type/text"
# Unicode Character Strings
require "active_record/connection_adapters/sqlserver/type/unicode_string"
require "active_record/connection_adapters/sqlserver/type/unicode_char"
require "active_record/connection_adapters/sqlserver/type/unicode_varchar"
require "active_record/connection_adapters/sqlserver/type/unicode_varchar_max"
require "active_record/connection_adapters/sqlserver/type/unicode_text"
# Binary Strings
require "active_record/connection_adapters/sqlserver/type/binary"
require "active_record/connection_adapters/sqlserver/type/varbinary"
require "active_record/connection_adapters/sqlserver/type/varbinary_max"
# Other Data Types
require "active_record/connection_adapters/sqlserver/type/uuid"
require "active_record/connection_adapters/sqlserver/type/timestamp"
require "active_record/connection_adapters/sqlserver/type/json"

module ActiveRecord
  module Type
    SQLServer = ConnectionAdapters::SQLServer::Type
  end
end
