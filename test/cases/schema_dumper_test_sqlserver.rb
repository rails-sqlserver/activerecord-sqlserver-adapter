# frozen_string_literal: true

require "cases/helper_sqlserver"

class SchemaDumperTestSQLServer < ActiveRecord::TestCase
  before { all_tables }

  let(:all_tables)   { ActiveRecord::Base.connection.tables }
  let(:schema)       { @generated_schema }

  it "sst_datatypes" do
    generate_schema_for_table "sst_datatypes"

    assert_line :bigint,            type: "bigint",                                                     default: 42
    assert_line :int,               type: "integer",                                                    default: 42
    assert_line :smallint,          type: "integer",       limit: 2,                                    default: 42
    assert_line :tinyint,           type: "integer",       limit: 1,                                    default: 42
    assert_line :bit,               type: "boolean",                                                    default: true
    assert_line :decimal_9_2,       type: "decimal",                     precision: 9,     scale: 2,    default: 12345.01
    assert_line :numeric_18_0,      type: "decimal",                     precision: 18,                 default: 191
    assert_line :numeric_36_2,      type: "decimal",                     precision: 36,    scale: 2,    default: 12345678901234567890.01
    assert_line :money,             type: "money",                       precision: 19,    scale: 4,    default: 4.2
    assert_line :smallmoney,        type: "smallmoney",                  precision: 10,    scale: 4,    default: 4.2
    # Approximate Numerics
    assert_line :float,             type: "float",                                                      default: 123.00000001
    assert_line :real,              type: "real",                                                       default: 123.45
    # Date and Time
    assert_line :date,              type: "date",                                                       default: "01-01-0001"
    assert_line :datetime,          type: "datetime",                    precision: nil,                default: "01-01-1753 00:00:00.123"
    if connection_tds_73
      assert_line :datetime2_7,     type: "datetime",                    precision: 7,                  default: "12-31-9999 23:59:59.9999999"
      assert_line :datetime2_3,     type: "datetime",                    precision: 3
      assert_line :datetime2_1,     type: "datetime",                    precision: 1
    end
    assert_line :smalldatetime,     type: "smalldatetime",                                              default: "01-01-1901 15:45:00.0"
    if connection_tds_73
      assert_line :time_7,          type: "time",                        precision: 7,                  default: "04:20:00.2883215"
      assert_line :time_2,          type: "time",                        precision: 2
      assert_line :time_default,    type: "time",                        precision: 7,                  default: "15:03:42.0621978"
    end
    # Character Strings
    assert_line :char_10,           type: "char",          limit: 10,                                   default: "1234567890"
    assert_line :varchar_50,        type: "varchar",       limit: 50,                                   default: "test varchar_50"
    assert_line :varchar_max,       type: "varchar_max",                                                default: "test varchar_max"
    assert_line :text,              type: "text_basic",                                                 default: "test text"
    # Unicode Character Strings
    assert_line :nchar_10,          type: "nchar",         limit: 10,                                   default: "12345678åå"
    assert_line :nvarchar_50,       type: "string",        limit: 50,                                   default: "test nvarchar_50 åå"
    assert_line :nvarchar_max,      type: "text",                                                       default: "test nvarchar_max åå"
    assert_line :ntext,             type: "ntext",                                                      default: "test ntext åå"
    # Binary Strings
    assert_line :binary_49,         type: "binary_basic",  limit: 49
    assert_line :varbinary_49,      type: "varbinary",     limit: 49
    assert_line :varbinary_max,     type: "binary"
    # Other Data Types
    assert_line :uniqueidentifier,  type: "uuid",                                                       default: -> { "newid()" }
    assert_line :timestamp,         type: "ss_timestamp"
  end

  it "sst_datatypes_migration" do
    columns = SSTestDatatypeMigration.columns_hash
    generate_schema_for_table "sst_datatypes_migration"

    # Simple Rails conventions
    _(columns["integer_col"].sql_type).must_equal                "int(4)"
    _(columns["bigint_col"].sql_type).must_equal                 "bigint(8)"
    _(columns["boolean_col"].sql_type).must_equal                "bit"
    _(columns["decimal_col"].sql_type).must_equal                "decimal(18,0)"
    _(columns["float_col"].sql_type).must_equal                  "float"
    _(columns["string_col"].sql_type).must_equal                 "nvarchar(4000)"
    _(columns["text_col"].sql_type).must_equal                   "nvarchar(max)"
    _(columns["datetime_nil_precision_col"].sql_type).must_equal "datetime"
    _(columns["datetime_col"].sql_type).must_equal               "datetime2(6)"
    _(columns["timestamp_col"].sql_type).must_equal              "datetime2(6)"
    _(columns["time_col"].sql_type).must_equal                   "time(7)"
    _(columns["date_col"].sql_type).must_equal                   "date"
    _(columns["binary_col"].sql_type).must_equal                 "varbinary(max)"

    assert_line :integer_col,                type: "integer"
    assert_line :bigint_col,                 type: "bigint"
    assert_line :boolean_col,                type: "boolean"
    assert_line :decimal_col,                type: "decimal",              precision: 18
    assert_line :float_col,                  type: "float"
    assert_line :string_col,                 type: "string"
    assert_line :text_col,                   type: "text"
    assert_line :datetime_nil_precision_col, type: "datetime",             precision: nil
    assert_line :datetime_col,               type: "datetime"
    assert_line :datetime_col,               type: "datetime"
    assert_line :timestamp_col,              type: "datetime"
    assert_line :time_col,                   type: "time",                 precision: 7
    assert_line :date_col,                   type: "date"
    assert_line :binary_col,                 type: "binary"

    # Our type methods.
    _(columns["real_col"].sql_type).must_equal          "real"
    _(columns["money_col"].sql_type).must_equal         "money"
    _(columns["smalldatetime_col"].sql_type).must_equal "smalldatetime"
    _(columns["datetime2_col"].sql_type).must_equal     "datetime2(7)"
    _(columns["datetimeoffset"].sql_type).must_equal    "datetimeoffset(7)"
    _(columns["smallmoney_col"].sql_type).must_equal    "smallmoney"
    _(columns["char_col"].sql_type).must_equal          "char(1)"
    _(columns["varchar_col"].sql_type).must_equal       "varchar(8000)"
    _(columns["text_basic_col"].sql_type).must_equal    "text"
    _(columns["nchar_col"].sql_type).must_equal         "nchar(1)"
    _(columns["ntext_col"].sql_type).must_equal         "ntext"
    _(columns["binary_basic_col"].sql_type).must_equal  "binary(1)"
    _(columns["varbinary_col"].sql_type).must_equal     "varbinary(8000)"
    _(columns["uuid_col"].sql_type).must_equal          "uniqueidentifier"
    _(columns["sstimestamp_col"].sql_type).must_equal   "timestamp"
    _(columns["json_col"].sql_type).must_equal          "nvarchar(max)"

    assert_line :real_col,          type: "real"
    assert_line :money_col,         type: "money",                      precision: 19,  scale: 4
    assert_line :smalldatetime_col, type: "smalldatetime"
    assert_line :datetime2_col,     type: "datetime",                   precision: 7
    assert_line :datetimeoffset,    type: "datetimeoffset",             precision: 7
    assert_line :smallmoney_col,    type: "smallmoney",                 precision: 10,  scale: 4
    assert_line :char_col,          type: "char",           limit: 1
    assert_line :varchar_col,       type: "varchar"
    assert_line :text_basic_col,    type: "text_basic"
    assert_line :nchar_col,         type: "nchar",          limit: 1
    assert_line :ntext_col,         type: "ntext"
    assert_line :binary_basic_col,  type: "binary_basic",   limit: 1
    assert_line :varbinary_col,     type: "varbinary"
    assert_line :uuid_col,          type: "uuid"
    assert_line :sstimestamp_col,   type: "ss_timestamp",                                           null: false
    assert_line :json_col,          type: "text"
  end

  it "dump column collation" do
    generate_schema_for_table('sst_string_collation')

    assert_line :string_without_collation, type: "string"
    assert_line :string_default_collation, type: "varchar"
    assert_line :string_with_collation,    type: "varchar",                           collation: "SQL_Latin1_General_CP1_CS_AS"
    assert_line :varchar_with_collation,   type: "varchar",                           collation: "SQL_Latin1_General_CP1_CS_AS"
  end

  # Special Cases

  it "honor nonstandard primary keys" do
    generate_schema_for_table("movies") do |output|
      match = output.match(%r{create_table "movies"(.*)do})
      assert_not_nil(match, "nonstandardpk table not found")
      assert_match %r(primary_key: "movieid"), match[1], "non-standard primary key not preserved"
    end
  end

  it "no id with model driven primary key" do
    output = generate_schema_for_table "sst_no_pk_data"

    _(output).must_match %r{create_table "sst_no_pk_data".*id:\sfalse.*do}
    assert_line :name, type: "string"
  end

  it "dumps field with unique key constraints only once" do
    output = generate_schema_for_table "unique_key_dumped_table"

    _(output.scan('t.integer "unique_field"').length).must_equal(1)
  end

  private

  def generate_schema_for_table(*table_names)
    require "stringio"

    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = all_tables - table_names
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    @generated_schema = stream.string
    yield @generated_schema if block_given?
    @schema_lines = Hash.new
    type_matcher = /\A\s+t\.\w+\s+"(.*?)"[,\n]/
    @generated_schema.each_line do |line|
      next unless line =~ type_matcher

      @schema_lines[Regexp.last_match[1]] = SchemaLine.new(line)
    end
    @generated_schema
  end

  def line(column_name)
    @schema_lines[column_name.to_s]
  end

  def assert_line(column_name, expected_options = {})
    line = line(column_name)
    assert line, "Could not find line with column name: #{column_name.inspect} in schema:\n#{schema}"

    # Check that the expected and actual option keys.
    expected_options_keys = expected_options.keys
    expected_options_keys.delete(:type)
    _(expected_options_keys.sort).must_equal (line.options.keys.sort), "For column '#{column_name}' expected schema options and actual schema options do not match."

    # Check the expected and actual option values.
    expected_options.each do |key, expected|
      actual   = key == :type ? line.send(:type_method) : line.send(key)

      message  = "#{key.to_s.titleize} of #{expected.inspect} not found in:\n#{line}"

      if expected.nil?
        _(actual).must_be_nil message
      elsif expected.is_a?(Array)
        _(actual).must_include expected, message
      elsif expected.is_a?(Float)
        _(actual).must_be_close_to expected, 0.001
      elsif expected.is_a?(Proc)
        _(actual.call).must_equal(expected.call)
      else
        _(actual).must_equal expected, message
      end
    end
  end

  class SchemaLine
    LINE_PARSER = %r{t\.(\w+)\s+"(.*?)"[,\s+](.*)}

    attr_reader :line,
                :type_method,
                :col_name,
                :options

    def self.option(method_name)
      define_method(method_name) do
        if options.key?(method_name.to_sym)
          options[method_name.to_sym]
        else
          throw "Schema line does include the '#{method_name}' option!"
        end
      end
    end

    def initialize(line)
      @line = line
      @type_method, @col_name, @options = parse_line
    end

    option :limit
    option :precision
    option :scale
    option :default
    option :collation
    option :null

    def to_s
      line.squish
    end

    def inspect
      "#<SchemaLine col_name=#{col_name.inspect}, options=#{options.inspect}>"
    end

    private

    def parse_line
      _all, type_method, col_name, options = @line.match(LINE_PARSER).to_a
      options = parse_options(options)

      [type_method, col_name, options]
    end

    def parse_options(opts)
      if opts.present?
        eval "{#{opts}}"
      else
        {}
      end
    end
  end
end
