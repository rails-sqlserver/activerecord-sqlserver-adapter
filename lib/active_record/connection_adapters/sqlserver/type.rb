require 'active_record/type'
# Exact Numerics
require 'active_record/connection_adapters/sqlserver/type/integer.rb'
require 'active_record/connection_adapters/sqlserver/type/big_integer.rb'
require 'active_record/connection_adapters/sqlserver/type/small_integer.rb'
require 'active_record/connection_adapters/sqlserver/type/tiny_integer.rb'
require 'active_record/connection_adapters/sqlserver/type/boolean.rb'
require 'active_record/connection_adapters/sqlserver/type/decimal.rb'
require 'active_record/connection_adapters/sqlserver/type/money.rb'
require 'active_record/connection_adapters/sqlserver/type/small_money.rb'
# Approximate Numerics
require 'active_record/connection_adapters/sqlserver/type/float.rb'
require 'active_record/connection_adapters/sqlserver/type/real.rb'
# Date and Time
require 'active_record/connection_adapters/sqlserver/type/time_value_fractional.rb'
require 'active_record/connection_adapters/sqlserver/type/date.rb'
require 'active_record/connection_adapters/sqlserver/type/datetime.rb'
require 'active_record/connection_adapters/sqlserver/type/datetime2.rb'
require 'active_record/connection_adapters/sqlserver/type/datetimeoffset.rb'
require 'active_record/connection_adapters/sqlserver/type/smalldatetime.rb'
require 'active_record/connection_adapters/sqlserver/type/time.rb'
# Character Strings
require 'active_record/connection_adapters/sqlserver/type/string.rb'
require 'active_record/connection_adapters/sqlserver/type/char.rb'
require 'active_record/connection_adapters/sqlserver/type/varchar.rb'
require 'active_record/connection_adapters/sqlserver/type/varchar_max.rb'
require 'active_record/connection_adapters/sqlserver/type/text.rb'
# Unicode Character Strings
require 'active_record/connection_adapters/sqlserver/type/unicode_string.rb'
require 'active_record/connection_adapters/sqlserver/type/unicode_char.rb'
require 'active_record/connection_adapters/sqlserver/type/unicode_varchar.rb'
require 'active_record/connection_adapters/sqlserver/type/unicode_varchar_max.rb'
require 'active_record/connection_adapters/sqlserver/type/unicode_text.rb'
# Binary Strings
require 'active_record/connection_adapters/sqlserver/type/binary.rb'
require 'active_record/connection_adapters/sqlserver/type/varbinary.rb'
require 'active_record/connection_adapters/sqlserver/type/varbinary_max.rb'
# Other Data Types
require 'active_record/connection_adapters/sqlserver/type/uuid.rb'
require 'active_record/connection_adapters/sqlserver/type/timestamp.rb'

module ActiveRecord
  module Type
    SQLServer = ConnectionAdapters::SQLServer::Type
  end
end
