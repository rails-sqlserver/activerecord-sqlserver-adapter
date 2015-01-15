class SSTestNaturalPkData < ActiveRecord::Base
  self.table_name = 'sst_natural_pk_data'
  self.primary_key = 'legacy_id'
end
