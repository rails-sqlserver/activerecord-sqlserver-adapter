require 'cases/sqlserver_helper'

class SQLServerUUIDTest < ActiveRecord::TestCase
  class UUID < ActiveRecord::Base
    self.table_name = 'sql_server_uuids'
  end

  def setup
    @connection = ActiveRecord::Base.connection

    @connection.reconnect!

    @connection.transaction do
      @connection.create_table('sql_server_uuids', id: :uuid, default: 'NEWSEQUENTIALID()') do |t|
        t.string 'name'
        t.uuid 'other_uuid', default: 'NEWID()'
      end
    end
  end

  def teardown
    @connection.execute "IF OBJECT_ID('sql_server_uuids', 'U') IS NOT NULL DROP TABLE sql_server_uuids"
  end

  def test_id_is_uuid
    assert_equal :uuid, UUID.columns_hash['id'].type
    assert UUID.primary_key
  end

  def test_id_has_a_default
    u = UUID.create
    assert_not_nil u.id
  end

  def test_auto_create_uuid
    u = UUID.create
    u.reload
    assert_not_nil u.other_uuid
  end

  def test_pk_and_sequence_for_uuid_primary_key
    pk, seq = @connection.pk_and_sequence_for('sql_server_uuids')
    assert_equal 'id', pk
    assert_equal nil, seq
  end

  def primary_key_for_uuid_primary_key
    assert_equal 'id', @connection.primary_key('sql_server_uuids')
  end

  def test_change_column_default
    @connection.add_column :sql_server_uuids, :thingy, :uuid, null: false, default: "NEWSEQUENTIALID()"
    UUID.reset_column_information
    column = UUID.columns.find { |c| c.name == 'thingy' }
    assert_equal "newsequentialid()", column.default_function

    @connection.change_column :sql_server_uuids, :thingy, :uuid, null: false, default: "NEWID()"

    UUID.reset_column_information
    column = UUID.columns.find { |c| c.name == 'thingy' }
    assert_equal "newid()", column.default_function
  end
end

class SQLServerUUIDTestNilDefault < ActiveRecord::TestCase
  class UUID < ActiveRecord::Base
    self.table_name = 'sql_server_uuids'
  end

  def setup
    @connection = ActiveRecord::Base.connection

    @connection.reconnect!

    @connection.transaction do
      @connection.create_table('sql_server_uuids', id: false) do |t|
        t.primary_key :id, :uuid, default: nil
        t.string 'name'
      end
    end
  end

  def teardown
    @connection.execute "IF OBJECT_ID('sql_server_uuids', 'U') IS NOT NULL DROP TABLE sql_server_uuids"
  end

end

class SQLServerUUIDTestInverseOf < ActiveRecord::TestCase
  class UuidPost < ActiveRecord::Base
    self.table_name = 'sql_server_uuid_posts'
    has_many :uuid_comments, inverse_of: :uuid_post
  end

  class UuidComment < ActiveRecord::Base
    self.table_name = 'sql_server_uuid_comments'
    belongs_to :uuid_post
  end

  def setup
    @connection = ActiveRecord::Base.connection
    @connection.reconnect!

    @connection.transaction do
      @connection.create_table('sql_server_uuid_posts', id: :uuid) do |t|
        t.string 'title'
      end
      @connection.create_table('sql_server_uuid_comments', id: :uuid) do |t|
        t.uuid :uuid_post_id, default: 'NEWID()'
        t.string 'content'
      end
    end
  end

  def teardown
    @connection.transaction do
      @connection.execute "IF OBJECT_ID('sql_server_uuid_comments', 'U') IS NOT NULL DROP TABLE sql_server_uuid_comments"
      @connection.execute "IF OBJECT_ID('sql_server_uuid_posts', 'U') IS NOT NULL DROP TABLE sql_server_uuid_posts"
    end
  end

  def test_collection_association_with_uuid
    post    = UuidPost.create!
    comment = post.uuid_comments.create!
    assert post.uuid_comments.find(comment.id)
  end
end
