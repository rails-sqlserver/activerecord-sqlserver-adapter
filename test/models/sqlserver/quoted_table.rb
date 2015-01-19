class SSTestQuotedTable < ActiveRecord::Base
  self.table_name = '[sst_quoted-table]'
end

class SSTestQuotedTableUser < ActiveRecord::Base
  self.table_name = '[dbo].[sst_quoted-table]'
end
