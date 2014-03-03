class SqlServerEdgeSchema < ActiveRecord::Base
  attr_accessor :new_id_setting
  before_create :set_new_id
  def with_spaces
    read_attribute :'with spaces'
  end

  def with_spaces=(value)
    write_attribute :'with spaces', value
  end

  protected
  def set_new_id
    self[:guid_newid] ||= self.class.connection.newid_function if new_id_setting
  end

end