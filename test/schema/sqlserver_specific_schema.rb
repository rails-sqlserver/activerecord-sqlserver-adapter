# frozen_string_literal: true

ActiveRecord::Schema.define do
  # Exhaustive Data Types

  execute File.read(ARTest::SQLServer.schema_datatypes_2012_file)

  create_table :sst_datatypes_migration, force: true do |t|
    # Simple Rails conventions.
    t.integer   :integer_col
    t.bigint    :bigint_col
    t.boolean   :boolean_col
    t.decimal   :decimal_col
    t.float     :float_col
    t.string    :string_col
    t.text      :text_col
    t.datetime  :datetime_col
    t.timestamp :timestamp_col
    t.time      :time_col
    t.date      :date_col
    t.binary    :binary_col
    # Our type methods.
    t.real           :real_col
    t.money          :money_col
    t.smalldatetime  :smalldatetime_col
    t.datetime2      :datetime2_col
    t.datetimeoffset :datetimeoffset
    t.smallmoney     :smallmoney_col
    t.char           :char_col
    t.varchar        :varchar_col
    t.text_basic     :text_basic_col
    t.nchar          :nchar_col
    t.ntext          :ntext_col
    t.binary_basic   :binary_basic_col
    t.varbinary      :varbinary_col
    t.uuid           :uuid_col
    t.ss_timestamp   :sstimestamp_col
    if supports_json?
      t.json :json_col
    else
      t.text :json_col
    end
  end

  # Edge Cases

  if ENV["IN_MEMORY_OLTP"] && supports_in_memory_oltp?
    create_table "sst_memory", force: true, id: false,
                               options: "WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)" do |t|
      t.primary_key_nonclustered :id
      t.string :name
      t.timestamps
    end
  end

  create_table "sst_bookings", force: true do |t|
    t.string :name
    t.datetime2 :created_at, null: false
    t.datetime2 :updated_at, null: false
  end

  create_table "sst_uuids", force: true, id: :uuid do |t|
    t.string :name
    t.uuid   :other_uuid, default: "NEWID()"
    t.uuid   :uuid_nil_default, default: nil
  end

  create_table "sst_my$strange_table", force: true do |t|
    t.string :name
  end

  create_table :SST_UPPER_TESTS, force: true do |t|
    t.column :COLUMN1, :string
    t.column :COLUMN2, :integer
  end

  create_table :sst_no_pk_data, force: true, id: false do |t|
    t.string :name
  end

  create_table "sst_quoted-table", force: true do |t|
  end
  execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'sst_quoted-view1') DROP VIEW [sst_quoted-view1]"
  execute "CREATE VIEW [sst_quoted-view1] AS SELECT * FROM [sst_quoted-table]"
  execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'sst_quoted-view2') DROP VIEW [sst_quoted-view2]"
  execute "CREATE VIEW [sst_quoted-view2] AS \n /*#{'x' * 4000}}*/ \n SELECT * FROM [sst_quoted-table]"

  create_table :sst_string_defaults, force: true do |t|
    t.column :string_with_null_default, :string, default: nil
    t.column :string_with_pretend_null_one, :string, default: "null"
    t.column :string_with_pretend_null_two, :string, default: "(null)"
    t.column :string_with_pretend_null_three, :string, default: "NULL"
    t.column :string_with_pretend_null_four, :string, default: "(NULL)"
    t.column :string_with_pretend_paren_three, :string, default: "(3)"
    t.column :string_with_multiline_default, :string, default: "Some long default with a\nnew line."
  end

  create_table :sst_edge_schemas, force: true do |t|
    t.string :description
    t.column "crazy]]quote", :string
    t.column "with spaces", :string
  end

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_natural_pk_data') DROP TABLE sst_natural_pk_data"
  execute <<-NATURALPKTABLESQL
    CREATE TABLE sst_natural_pk_data(
      parent_id int,
      name nvarchar(255),
      description nvarchar(1000),
      legacy_id nvarchar(10) NOT NULL PRIMARY KEY
    )
  NATURALPKTABLESQL

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_natural_pk_int_data') DROP TABLE sst_natural_pk_int_data"
  execute <<-NATURALPKINTTABLESQL
    CREATE TABLE sst_natural_pk_int_data(
      legacy_id int NOT NULL PRIMARY KEY,
      parent_id int,
      name nvarchar(255),
      description nvarchar(1000)
    )
  NATURALPKINTTABLESQL

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_tinyint_pk') DROP TABLE sst_tinyint_pk"
  execute <<-TINYITPKTABLE
    CREATE TABLE sst_tinyint_pk(
      id tinyint IDENTITY NOT NULL PRIMARY KEY,
      name nvarchar(255)
    )
  TINYITPKTABLE

  execute "DROP DEFAULT [sst_getdateobject];" rescue nil
  execute "CREATE DEFAULT [sst_getdateobject] AS getdate();" rescue nil
  create_table "sst_defaultobjects", force: true do |t|
    t.string :name
    t.date   :date
  end
  execute "sp_bindefault 'sst_getdateobject', 'sst_defaultobjects.date'"

  execute "DROP PROCEDURE my_getutcdate" rescue nil
  execute <<-SQL
    CREATE PROCEDURE my_getutcdate AS
    SELECT GETUTCDATE() utcdate
  SQL

  # Constraints

  create_table(:sst_has_fks, force: true) do |t|
    t.column(:fk_id, :bigint, null: false)
    t.column(:fk_id2, :bigint)
  end

  create_table(:sst_has_pks, force: true) {}
  execute <<-ADDFKSQL
    ALTER TABLE sst_has_fks
    ADD CONSTRAINT FK__sst_has_fks_id
    FOREIGN KEY ([fk_id])
    REFERENCES [sst_has_pks] ([id]),

    CONSTRAINT FK__sst_has_fks_id2
    FOREIGN KEY ([fk_id2])
    REFERENCES [sst_has_pks] ([id])
  ADDFKSQL

  # Views

  execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'sst_customers_view') DROP VIEW sst_customers_view"
  execute <<-CUSTOMERSVIEW
    CREATE VIEW sst_customers_view AS
      SELECT id, name, balance
      FROM customers
  CUSTOMERSVIEW

  execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'sst_string_defaults_view') DROP VIEW sst_string_defaults_view"
  execute <<-STRINGDEFAULTSVIEW
    CREATE VIEW sst_string_defaults_view AS
      SELECT id, string_with_pretend_null_one as pretend_null
      FROM sst_string_defaults
  STRINGDEFAULTSVIEW

  execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'sst_string_defaults_big_view') DROP VIEW sst_string_defaults_big_view"
  execute <<-STRINGDEFAULTSBIGVIEW
    CREATE VIEW sst_string_defaults_big_view AS
      SELECT id, string_with_pretend_null_one as pretend_null
      /*#{'x' * 4000}}*/
      FROM sst_string_defaults
  STRINGDEFAULTSBIGVIEW

  # Trigger

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_table_with_trigger') DROP TABLE sst_table_with_trigger"
  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_table_with_trigger_history') DROP TABLE sst_table_with_trigger_history"
  execute <<-SQL
    CREATE TABLE sst_table_with_trigger(
      id bigint IDENTITY NOT NULL PRIMARY KEY,
      event_name nvarchar(255)
    )
    CREATE TABLE sst_table_with_trigger_history(
      id bigint IDENTITY NOT NULL PRIMARY KEY,
      id_source nvarchar(36),
      event_name nvarchar(255)
    )
  SQL
  execute <<-SQL
    CREATE TRIGGER sst_table_with_trigger_t ON sst_table_with_trigger
    FOR INSERT
    AS
    INSERT INTO sst_table_with_trigger_history (id_source, event_name)
    SELECT id AS id_source, event_name FROM INSERTED
  SQL

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_table_with_uuid_trigger') DROP TABLE sst_table_with_uuid_trigger"
  execute <<-SQL
    CREATE TABLE sst_table_with_uuid_trigger(
      id uniqueidentifier DEFAULT NEWID() PRIMARY KEY,
      event_name nvarchar(255)
    )
  SQL
  execute <<-SQL
    CREATE TRIGGER sst_table_with_uuid_trigger_t ON sst_table_with_uuid_trigger
    FOR INSERT
    AS
    INSERT INTO sst_table_with_trigger_history (id_source, event_name)
    SELECT id AS id_source, event_name FROM INSERTED
  SQL

  # Another schema.

  create_table :sst_schema_columns, force: true do |t|
    t.column :field1, :integer
  end

  execute "IF NOT EXISTS(SELECT * FROM sys.schemas WHERE name = 'test') EXEC sp_executesql N'CREATE SCHEMA test'"
  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_schema_columns' and TABLE_SCHEMA = 'test') DROP TABLE test.sst_schema_columns"
  execute <<-SIMILIARTABLEINOTHERSCHEMA
    CREATE TABLE test.sst_schema_columns(
      id int IDENTITY NOT NULL primary key,
      filed_1 int,
      field_2 int,
      name varchar(255),
      description varchar(1000),
      n_name nvarchar(255),
      n_description nvarchar(1000)
    )
  SIMILIARTABLEINOTHERSCHEMA

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_schema_identity' and TABLE_SCHEMA = 'test') DROP TABLE test.sst_schema_identity"
  execute <<-SIMILIARTABLEINOTHERSCHEMA
    CREATE TABLE test.sst_schema_identity(
      id int IDENTITY NOT NULL primary key,
      filed_1 int
    )
  SIMILIARTABLEINOTHERSCHEMA

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_schema_natural_id' and TABLE_SCHEMA = 'test') DROP TABLE test.sst_schema_natural_id"
  execute <<-NATURALPKTABLESQLINOTHERSCHEMA
    CREATE TABLE test.sst_schema_natural_id(
      parent_id int,
      name nvarchar(255),
      description nvarchar(1000),
      legacy_id nvarchar(10) NOT NULL PRIMARY KEY,
    )
  NATURALPKTABLESQLINOTHERSCHEMA

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_schema_test_mulitple_schema' and TABLE_SCHEMA = 'test') DROP TABLE test.sst_schema_test_mulitple_schema"
  execute <<-SCHEMATESTMULTIPLESCHEMA
    CREATE TABLE test.sst_schema_test_mulitple_schema(
      field_1 int NOT NULL PRIMARY KEY,
      field_2 int,
    )
  SCHEMATESTMULTIPLESCHEMA
  execute "IF NOT EXISTS(SELECT * FROM sys.schemas WHERE name = 'test2') EXEC sp_executesql N'CREATE SCHEMA test2'"
  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sst_schema_test_mulitple_schema' and TABLE_SCHEMA = 'test2') DROP TABLE test2.sst_schema_test_mulitple_schema"
  execute <<-SCHEMATESTMULTIPLESCHEMA
    CREATE TABLE test2.sst_schema_test_mulitple_schema(
      field_1 int,
      field_2 int NOT NULL PRIMARY KEY,
    )
  SCHEMATESTMULTIPLESCHEMA
end
