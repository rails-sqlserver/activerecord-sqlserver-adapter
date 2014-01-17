class Person < ActiveRecord::Base
  coerce_sqlserver_date :favorite_day
end
