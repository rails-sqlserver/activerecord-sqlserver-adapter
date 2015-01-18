ActiveRecord::Schema.define do

  # Exhaustive Data Types

  execute File.read(ARTest::SQLServer.schema_datatypes_2012_file)

  create_table :sst_datatypes_migration, force: true do |t|
    t.column :real, :real
  end


  # Edge Cases

  create_table 'sst_my$strange_table', force: true do |t|
    t.column :number, :real
  end

  create_table :SST_UPPER_TESTS, force: true do |t|
    t.column :COLUMN1, :string
    t.column :COLUMN2, :integer
  end

  create_table :sst_no_pk_data, force: true, id: false do |t|
    t.string :name
  end

  create_table 'sst_quoted-table', force: true do |t|
  end
  execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'sst_quoted-view1') DROP VIEW [sst_quoted-view1]"
  execute "CREATE VIEW [sst_quoted-view1] AS SELECT * FROM [sst_quoted-table]"
  execute "IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'sst_quoted-view2') DROP VIEW [sst_quoted-view2]"
  execute "CREATE VIEW [sst_quoted-view2] AS \n /*#{'x'*4000}}*/ \n SELECT * FROM [sst_quoted-table]"

  create_table :sst_string_defaults, force: true do |t|
    t.column :string_with_null_default, :string, default: nil
    t.column :string_with_pretend_null_one, :string, default: 'null'
    t.column :string_with_pretend_null_two, :string, default: '(null)'
    t.column :string_with_pretend_null_three, :string, default: 'NULL'
    t.column :string_with_pretend_null_four, :string, default: '(NULL)'
    t.column :string_with_pretend_paren_three, :string, default: '(3)'
    t.column :string_with_multiline_default, :string, default: "Some long default with a\nnew line."
  end

  create_table :sst_edge_schemas, force: true do |t|
    t.string :description
    t.column :guid, :uniqueidentifier
    t.column 'crazy]]quote', :string
    t.column 'with spaces', :string
  end
  execute %|ALTER TABLE [sst_edge_schemas] ADD [guid_newid] uniqueidentifier DEFAULT NEWID();|
  execute %|ALTER TABLE [sst_edge_schemas] ADD [guid_newseqid] uniqueidentifier DEFAULT NEWSEQUENTIALID();|

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


  # Constraints

  create_table(:sst_has_fks, force: true) { |t| t.column(:fk_id, :integer, null: false) }
  create_table(:sst_has_pks, force: true) { }
  execute <<-ADDFKSQL
    ALTER TABLE sst_has_fks
    ADD CONSTRAINT FK__sst_has_fks_id
    FOREIGN KEY ([fk_id])
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
      /*#{'x'*4000}}*/
      FROM sst_string_defaults
  STRINGDEFAULTSBIGVIEW










  create_table :defaults, force: true do |t|
    t.column :positive_integer, :integer, default: 1
    t.column :negative_integer, :integer, default: -1
    t.column :decimal_number, :decimal, precision: 3, scale: 2, default: 2.78
  end

  # http://blogs.msdn.com/b/craigfr/archive/2008/03/19/ranking-functions-row-number.aspx
  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'order_row_number') DROP TABLE order_row_number"
  execute <<-ORDERROWNUMBERSQL
    CREATE TABLE [order_row_number] (id int IDENTITY, a int, b int, c int)
    CREATE UNIQUE CLUSTERED INDEX [idx_order_row_number_id] ON [order_row_number] ([id])
    INSERT [order_row_number] VALUES (0, 1, 8)
    INSERT [order_row_number] VALUES (0, 3, 6)
    INSERT [order_row_number] VALUES (0, 5, 4)
    INSERT [order_row_number] VALUES (0, 7, 2)
    INSERT [order_row_number] VALUES (0, 9, 0)
    INSERT [order_row_number] VALUES (1, 0, 9)
    INSERT [order_row_number] VALUES (1, 2, 7)
    INSERT [order_row_number] VALUES (1, 4, 5)
    INSERT [order_row_number] VALUES (1, 6, 3)
    INSERT [order_row_number] VALUES (1, 8, 1)
  ORDERROWNUMBERSQL

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'tinyint_pk_table') DROP TABLE tinyint_pk_table"
  execute <<-TINYITPKTABLE
    CREATE TABLE tinyint_pk_table(
      id tinyint NOT NULL PRIMARY KEY,
      name nvarchar(255)
    )
  TINYITPKTABLE












  # Another schema.

  create_table :sql_server_schema_columns, force: true do |t|
    t.column :field1 , :integer
  end

  execute "IF NOT EXISTS(SELECT * FROM sys.schemas WHERE name = 'test') EXEC sp_executesql N'CREATE SCHEMA test'"
  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sql_server_schema_columns' and TABLE_SCHEMA = 'test') DROP TABLE test.sql_server_schema_columns"
  execute <<-SIMILIARTABLEINOTHERSCHEMA
    CREATE TABLE test.sql_server_schema_columns(
      id int IDENTITY NOT NULL primary key,
      filed_1 int,
      field_2 int,
      name varchar(255),
      description varchar(1000),
      n_name nvarchar(255),
      n_description nvarchar(1000)
    )
  SIMILIARTABLEINOTHERSCHEMA

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sql_server_schema_identity' and TABLE_SCHEMA = 'test') DROP TABLE test.sql_server_schema_identity"
  execute <<-SIMILIARTABLEINOTHERSCHEMA
    CREATE TABLE test.sql_server_schema_identity(
      id int IDENTITY NOT NULL primary key,
      filed_1 int
    )
  SIMILIARTABLEINOTHERSCHEMA

  execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'sql_server_schema_natural_id' and TABLE_SCHEMA = 'test') DROP TABLE test.sql_server_schema_natural_id"
  execute <<-NATURALPKTABLESQLINOTHERSCHEMA
    CREATE TABLE test.sql_server_schema_natural_id(
      parent_id int,
      name nvarchar(255),
      description nvarchar(1000),
      legacy_id nvarchar(10) NOT NULL PRIMARY KEY,
    )
  NATURALPKTABLESQLINOTHERSCHEMA

end
