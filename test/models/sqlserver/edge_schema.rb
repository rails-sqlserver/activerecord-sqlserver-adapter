class SSTestEdgeSchema < ActiveRecord::Base

  self.table_name = 'sst_edge_schemas'

  def with_spaces
    read_attribute :'with spaces'
  end

  def with_spaces=(value)
    write_attribute :'with spaces', value
  end

end
