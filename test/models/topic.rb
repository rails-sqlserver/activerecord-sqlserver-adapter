class Topic < ActiveRecord::Base
  coerce_sqlserver_date :last_read
  coerce_sqlserver_time :bonus_time
end