class SqlServerChronic < ActiveRecord::Base
  coerce_sqlserver_date :date
  coerce_sqlserver_time :time
  default_timezone = :utc
end
