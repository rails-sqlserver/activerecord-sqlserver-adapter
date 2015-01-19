require 'active_record/type'
require 'active_record/connection_adapters/sqlserver/type/core_ext/value.rb'
require 'active_record/connection_adapters/sqlserver/type/castable.rb'
require 'active_record/connection_adapters/sqlserver/type/quoter.rb'
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
require 'active_record/connection_adapters/sqlserver/type/date.rb'
require 'active_record/connection_adapters/sqlserver/type/datetime.rb'
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
