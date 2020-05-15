# frozen_string_literal: true

class SSTestTrigger < ActiveRecord::Base
  self.table_name = "sst_table_with_trigger"
end

class SSTestTriggerUuid < ActiveRecord::Base
  self.table_name = "sst_table_with_uuid_trigger"
end
