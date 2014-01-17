class SqlServerNaturalPkData < ActiveRecord::Base
  self.table_name = 'natural_pk_data'
  self.primary_key = 'legacy_id'
end