class SqlServerDollarTableName < ActiveRecord::Base
  self.table_name = 'my$strange_table'
end