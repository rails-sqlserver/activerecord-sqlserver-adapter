require 'cases/helper_sqlserver'
require 'stringio'

class SchemaDumperTestSQLServer < ActiveRecord::TestCase

  before { all_tables }

  let(:all_tables)   { ActiveRecord::Base.connection.tables }
  let(:schema)       { @generated_schema }

  it 'sst_datatypes' do
    generate_schema_for_table 'sst_datatypes'
    # Exact Numerics
    assert_line :bigint,        type: 'integer',      limit: '8',           precision: nil,   scale: nil,  default: '42'
    assert_line :int,           type: 'integer',      limit: '4',           precision: nil,   scale: nil,  default: '42'
    assert_line :smallint,      type: 'integer',      limit: '2',           precision: nil,   scale: nil,  default: '42'
    assert_line :tinyint,       type: 'integer',      limit: '1',           precision: nil,   scale: nil,  default: '42'
    assert_line :bit,           type: 'boolean',      limit: nil,           precision: nil,   scale: nil,  default: 'true'
    assert_line :decimal_9_2,   type: 'decimal',      limit: nil,           precision: '9',   scale: '2',  default: '12345.01'
    assert_line :numeric_18_0,  type: 'decimal',      limit: nil,           precision: '18',  scale: '0',  default: '191.0'
    assert_line :numeric_36_2,  type: 'decimal',      limit: nil,           precision: '36',  scale: '2',  default: '12345678901234567890.01'
    assert_line :money,         type: 'money',        limit: nil,           precision: '19',  scale: '4',  default: '4.2'
    assert_line :smallmoney,    type: 'smallmoney',   limit: nil,           precision: '10',  scale: '4',  default: '4.2'
    # Approximate Numerics
    assert_line :float,         type: 'float',        limit: '53',          precision: nil,   scale: nil,  default: '123.00000001'
    assert_line :float_25,      type: 'float',        limit: '53',          precision: nil,   scale: nil,  default: '420.11'
    assert_line :real,          type: 'real',         limit: '24',          precision: nil,   scale: nil,  default: %r{123.4[45]}
    # Date and Time
    assert_line :date,          type: 'date',         limit: nil,           precision: nil,   scale: nil,  default: "'0001-01-01'"
    assert_line :datetime,      type: 'datetime',     limit: nil,           precision: nil,   scale: nil,  default: "'1753-01-01 00:00:00'"
    assert_line :smalldatetime, type: 'datetime',     limit: nil,           precision: nil,   scale: nil,  default: "'1901-01-01 15:45:00'"
    assert_line :time_2,        type: 'time',         limit: nil,           precision: '2',   scale: nil,  default: nil
    assert_line :time_7,        type: 'time',         limit: nil,           precision: '7',   scale: nil,  default: nil
    # Character Strings
    assert_line :char_10,       type: 'char',         limit: '10',          precision: nil,   scale: nil,  default: "\"1234567890\""
    assert_line :varchar_50,    type: 'varchar',      limit: '50',          precision: nil,   scale: nil,  default: "\"test varchar_50\""
    assert_line :varchar_max,   type: 'varchar_max',  limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test varchar_max\""
    assert_line :text,          type: 'text_basic',   limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test text\""
    # Unicode Character Strings
    assert_line :nchar_10,      type: 'nchar',        limit: '10',          precision: nil,   scale: nil,  default: "\"12345678åå\""
    assert_line :nvarchar_50,   type: 'string',       limit: '50',          precision: nil,   scale: nil,  default: "\"test nvarchar_50 åå\""
    assert_line :nvarchar_max,  type: 'text',         limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test nvarchar_max åå\""
    assert_line :ntext,         type: 'ntext',        limit: '2147483647',  precision: nil,   scale: nil,  default: "\"test ntext åå\""
    # Binary Strings
    assert_line :binary_49,     type: 'binary_basic', limit: '49',          precision: nil,   scale: nil,  default: nil
    assert_line :varbinary_49,  type: 'varbinary',    limit: '49',          precision: nil,   scale: nil,  default: nil
    assert_line :varbinary_max, type: 'binary',       limit: '2147483647',  precision: nil,   scale: nil,  default: nil
  end

  it 'primary_key' do
    generate_schema_for_table('movies') do |output|
      match = output.match(%r{create_table "movies"(.*)do})
      assert_not_nil(match, "nonstandardpk table not found")
      assert_match %r(primary_key: "movieid"), match[1], "non-standard primary key not preserved"
    end
  end


  private

  def generate_schema_for_table(*table_names)
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = all_tables - table_names
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    @generated_schema = stream.string
    yield @generated_schema if block_given?
    @schema_lines = Hash.new
    type_matcher = /\A\s+t\.\w+\s+"(.*?)",/
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
    assert line, "Count not find line with column name: #{column_name.inspect}"
    line.type_method.must_equal  options[:type],      "Type of #{options[:type].inspect} not found in:\n #{line}"            if options.key?(:type)
    line.limit.must_equal        options[:limit],     "Limit of #{options[:limit].inspect} not found in:\n #{line}"          if options.key?(:limit)
    line.precision.must_equal    options[:precision], "Precision of #{options[:precision].inspect} not found in:\n #{line}"  if options.key?(:precision)
    line.scale.must_equal        options[:scale],     "Scale of #{options[:scale].inspect} not found in:\n #{line}"          if options.key?(:scale)
    line.default.must_equal      options[:default],   "Default of #{options[:default].inspect} not found in:\n #{line}"      if options.key?(:default) && options[:default].is_a?(String)
    line.default.must_match      options[:default],   "Default of #{options[:default].inspect} not found in:\n #{line}"      if options.key?(:default) && options[:default].is_a?(Regexp)
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

