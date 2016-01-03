require 'cases/helper_sqlserver'

class SchemaDumperTestSQLServer < ActiveRecord::TestCase

  before { all_tables }

  let(:all_tables)   { ActiveRecord::Base.connection.tables }
  let(:schema)       { @generated_schema }

  it 'sst_datatypes' do
    generate_schema_for_table 'sst_datatypes'
    # Exact Numerics
    assert_line :bigint,            type: 'bigint',       limit: '8',           precision: nil,   scale: nil,  default: '42'
    assert_line :int,               type: 'integer',      limit: '4',           precision: nil,   scale: nil,  default: '42'
    assert_line :smallint,          type: 'integer',      limit: '2',           precision: nil,   scale: nil,  default: '42'
    assert_line :tinyint,           type: 'integer',      limit: '1',           precision: nil,   scale: nil,  default: '42'
    assert_line :bit,               type: 'boolean',      limit: nil,           precision: nil,   scale: nil,  default: 'true'
    assert_line :decimal_9_2,       type: 'decimal',      limit: nil,           precision: '9',   scale: '2',  default: '12345.01'
    assert_line :numeric_18_0,      type: 'decimal',      limit: nil,           precision: '18',  scale: '0',  default: '191.0'
    assert_line :numeric_36_2,      type: 'decimal',      limit: nil,           precision: '36',  scale: '2',  default: '12345678901234567890.01'
    assert_line :money,             type: 'money',        limit: nil,           precision: '19',  scale: '4',  default: '4.2'
    assert_line :smallmoney,        type: 'smallmoney',   limit: nil,           precision: '10',  scale: '4',  default: '4.2'
    # Approximate Numerics
    assert_line :float,             type: 'float',        limit: nil,          precision: nil,   scale: nil,  default: '123.00000001'
    assert_line :real,              type: 'real',         limit: nil,          precision: nil,   scale: nil,  default: %r{123.4[45]}
    # Date and Time
    assert_line :date,              type: 'date',         limit: nil,           precision: nil,   scale: nil,  default: "\"01-01-0001\""
    assert_line :datetime,          type: 'datetime',     limit: nil,           precision: nil,   scale: nil,  default: "\"01-01-1753 00:00:00.123\""
    if connection_dblib_73?
    assert_line :datetime2_7,       type: 'datetime2',    limit: nil,           precision: '7',   scale: nil,  default: "\"12-31-9999 23:59:59.9999999\""
    assert_line :datetime2_3,       type: 'datetime2',    limit: nil,           precision: '3',   scale: nil,  default: nil
    assert_line :datetime2_1,       type: 'datetime2',    limit: nil,           precision: '1',   scale: nil,  default: nil
    end
    assert_line :smalldatetime,     type: 'smalldatetime',limit: nil,           precision: nil,   scale: nil,  default: "\"01-01-1901 15:45:00\""
    if connection_dblib_73?
    assert_line :time_7,            type: 'time',         limit: nil,           precision: '7',   scale: nil,  default: "\"04:20:00.2883215\""
    assert_line :time_2,            type: 'time',         limit: nil,           precision: '2',   scale: nil,  default: nil
    end
    # Character Strings
    assert_line :char_10,           type: 'char',         limit: '10',          precision: nil,   scale: nil,  default: "\"1234567890\""
    assert_line :varchar_50,        type: 'varchar',      limit: '50',          precision: nil,   scale: nil,  default: "\"test varchar_50\""
    assert_line :varchar_max,       type: 'varchar_max',  limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test varchar_max\""
    assert_line :text,              type: 'text_basic',   limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test text\""
    # Unicode Character Strings
    assert_line :nchar_10,          type: 'nchar',        limit: '10',          precision: nil,   scale: nil,  default: "\"12345678åå\""
    assert_line :nvarchar_50,       type: 'string',       limit: '50',          precision: nil,   scale: nil,  default: "\"test nvarchar_50 åå\""
    assert_line :nvarchar_max,      type: 'text',         limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test nvarchar_max åå\""
    assert_line :ntext,             type: 'ntext',        limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test ntext åå\""
    # Binary Strings
    assert_line :binary_49,         type: 'binary_basic', limit: '49',          precision: nil,   scale: nil,  default: nil
    assert_line :varbinary_49,      type: 'varbinary',    limit: '49',          precision: nil,   scale: nil,  default: nil
    assert_line :varbinary_max,     type: 'binary',       limit: '2147483647',  precision: nil,   scale: nil,  default: nil
    # Other Data Types
    assert_line :uniqueidentifier,  type: 'uuid',         limit: nil,           precision: nil,   scale: nil,  default: nil
    assert_line :timestamp,         type: 'ss_timestamp', limit: nil,           precision: nil,   scale: nil,  default: nil
  end

  it 'sst_datatypes_migration' do
    columns = SSTestDatatypeMigration.columns_hash
    generate_schema_for_table 'sst_datatypes_migration'
    # Simple Rails conventions
    columns['integer_col'].sql_type.must_equal      'int(4)'
    columns['bigint_col'].sql_type.must_equal       'bigint(8)'
    columns['boolean_col'].sql_type.must_equal      'bit'
    columns['decimal_col'].sql_type.must_equal      'decimal(18,0)'
    columns['float_col'].sql_type.must_equal        'float'
    columns['string_col'].sql_type.must_equal       'nvarchar(4000)'
    columns['text_col'].sql_type.must_equal         'nvarchar(max)'
    columns['datetime_col'].sql_type.must_equal     'datetime'
    columns['timestamp_col'].sql_type.must_equal    'datetime'
    columns['time_col'].sql_type.must_equal         'time(7)'
    columns['date_col'].sql_type.must_equal         'date'
    columns['binary_col'].sql_type.must_equal       'varbinary(max)'
    assert_line :integer_col,     type: 'integer',      limit: '4',          precision: nil,  scale: nil, default: nil
    assert_line :bigint_col,      type: 'bigint',       limit: '8',          precision: nil,  scale: nil, default: nil
    assert_line :boolean_col,     type: 'boolean',      limit: nil,          precision: nil,  scale: nil, default: nil
    assert_line :decimal_col,     type: 'decimal',      limit: nil,          precision: '18', scale: '0', default: nil
    assert_line :float_col,       type: 'float',        limit: nil,          precision: nil,  scale: nil, default: nil
    assert_line :string_col,      type: 'string',       limit: '4000',       precision: nil,  scale: nil, default: nil
    assert_line :text_col,        type: 'text',         limit: '2147483647', precision: nil,  scale: nil, default: nil
    assert_line :datetime_col,    type: 'datetime',     limit: nil,          precision: nil,  scale: nil, default: nil
    assert_line :timestamp_col,   type: 'datetime',     limit: nil,          precision: nil,  scale: nil, default: nil
    assert_line :time_col,        type: 'time',         limit: nil,          precision: '7',  scale: nil, default: nil
    assert_line :date_col,        type: 'date',         limit: nil,          precision: nil,  scale: nil, default: nil
    assert_line :binary_col,      type: 'binary',       limit: '2147483647', precision: nil,  scale: nil, default: nil
    # Our type methods.
    columns['real_col'].sql_type.must_equal         'real'
    columns['money_col'].sql_type.must_equal        'money'
    columns['datetime2_col'].sql_type.must_equal    'datetime2(7)'
    columns['datetimeoffset'].sql_type.must_equal   'datetimeoffset(7)'
    columns['smallmoney_col'].sql_type.must_equal   'smallmoney'
    columns['char_col'].sql_type.must_equal         'char(1)'
    columns['varchar_col'].sql_type.must_equal      'varchar(8000)'
    columns['text_basic_col'].sql_type.must_equal   'text'
    columns['nchar_col'].sql_type.must_equal        'nchar(1)'
    columns['ntext_col'].sql_type.must_equal        'ntext'
    columns['binary_basic_col'].sql_type.must_equal 'binary(1)'
    columns['varbinary_col'].sql_type.must_equal    'varbinary(8000)'
    columns['uuid_col'].sql_type.must_equal         'uniqueidentifier'
    columns['sstimestamp_col'].sql_type.must_equal  'timestamp'
    assert_line :real_col,          type: 'real',         limit: nil,           precision: nil,   scale: nil,  default: nil
    assert_line :money_col,         type: 'money',        limit: nil,           precision: '19',  scale: '4',  default: nil
    assert_line :datetime2_col,     type: 'datetime2',    limit: nil,           precision: '7',   scale: nil,  default: nil
    assert_line :smallmoney_col,    type: 'smallmoney',   limit: nil,           precision: '10',  scale: '4',  default: nil
    assert_line :char_col,          type: 'char',         limit: '1',           precision: nil,   scale: nil,  default: nil
    assert_line :varchar_col,       type: 'varchar',      limit: '8000',        precision: nil,   scale: nil,  default: nil
    assert_line :text_basic_col,    type: 'text_basic',   limit: '2147483647',  precision: nil,   scale: nil,  default: nil
    assert_line :nchar_col,         type: 'nchar',        limit: '1',           precision: nil,   scale: nil,  default: nil
    assert_line :ntext_col,         type: 'ntext',        limit: '2147483647',  precision: nil,   scale: nil,  default: nil
    assert_line :binary_basic_col,  type: 'binary_basic', limit: '1',           precision: nil,   scale: nil,  default: nil
    assert_line :varbinary_col,     type: 'varbinary',    limit: '8000',        precision: nil,   scale: nil,  default: nil
    assert_line :uuid_col,          type: 'uuid',         limit: nil,           precision: nil,   scale: nil,  default: nil
    assert_line :sstimestamp_col,   type: 'ss_timestamp', limit: nil,           precision: nil,   scale: nil,  default: nil
  end

  # Special Cases

  it 'honor nonstandard primary keys' do
    generate_schema_for_table('movies') do |output|
      match = output.match(%r{create_table "movies"(.*)do})
      assert_not_nil(match, "nonstandardpk table not found")
      assert_match %r(primary_key: "movieid"), match[1], "non-standard primary key not preserved"
    end
  end

  it 'no id with model driven primary key' do
    output = generate_schema_for_table 'sst_no_pk_data'
    output.must_match %r{create_table "sst_no_pk_data".*id:\sfalse.*do}
    assert_line :name, type: 'string', limit: '4000'
  end


  private

  def generate_schema_for_table(*table_names)
    require 'stringio'
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

  def assert_line(column_name, options={})
    line = line(column_name)
    assert line, "Count not find line with column name: #{column_name.inspect} in schema:\n#{schema}"
    [:type, :limit, :precision, :scale, :default].each do |key|
      next unless options.key?(key)
      actual   = key == :type ? line.send(:type_method) : line.send(key)
      expected = options[key]
      message  = "#{key.to_s.titleize} of #{expected.inspect} not found in:\n#{line}"
      if expected.nil?
        actual.must_be_nil message
      elsif expected.is_a?(Regexp)
        actual.must_match expected, message
      else
        actual.must_equal expected, message
      end
    end
  end

  class SchemaLine

    attr_reader :line

    def self.match(method_name, pattern)
      define_method(method_name) { line.match(pattern).try :[], 1 }
    end

    def initialize(line)
      @line = line
    end

    match :type_method,   %r{\A\s+t\.(.*?)\s}
    match :limit,         %r{\slimit:\s(.*?)[,\s]}
    match :default,       %r{\sdefault:\s(.*)\n}
    match :precision,     %r{\sprecision:\s(.*?)[,\s]}
    match :scale,         %r{\sscale:\s(.*?)[,\s]}

    def to_s
      line
    end

  end

end

