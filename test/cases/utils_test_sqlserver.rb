require 'cases/helper_sqlserver'

class UtilsTestSQLServer < ActiveRecord::TestCase

  it '.quote_string' do
    SQLServer::Utils.quote_string("I'll store this in C:\\Users").must_equal "I''ll store this in C:\\Users"
  end

  it '.unquote_string' do
    SQLServer::Utils.unquote_string("I''ll store this in C:\\Users").must_equal "I'll store this in C:\\Users"
  end

  describe '.extract_identifiers constructor and thus SQLServer::Utils::Name value object' do

    let(:valid_names) { valid_names_unquoted + valid_names_quoted }

    let(:valid_names_unquoted) {[
      'server.database.schema.object',
      'server.database..object',
      'server..schema.object',
      'server...object',
      'database.schema.object',
      'database..object',
      'schema.object',
      'object'
    ]}

    let(:valid_names_quoted) {[
      '[server].[database].[schema].[object]',
      '[server].[database]..[object]',
      '[server]..[schema].[object]',
      '[server]...[object]',
      '[database].[schema].[object]',
      '[database]..[object]',
      '[schema].[object]',
      '[object]'
    ]}

    let(:server_names)   { valid_names.partition { |name| name =~ /server/ } }
    let(:database_names) { valid_names.partition { |name| name =~ /database/ } }
    let(:schema_names)   { valid_names.partition { |name| name =~ /schema/ } }

    it 'extracts and returns #object identifier unquoted by default or quoted as needed' do
      valid_names.each do |n|
        name = SQLServer::Utils.extract_identifiers(n)
        name.object.must_equal 'object', "With #{n.inspect} for #object"
        name.object_quoted.must_equal '[object]', "With #{n.inspect} for #object_quoted"
      end
    end

    [:schema, :database, :server].each do |part|

      it "extracts and returns #{part} identifier unquoted by default or quoted as needed" do
        present, blank = send(:"#{part}_names")
        present.each do |n|
          name = SQLServer::Utils.extract_identifiers(n)
          name.send(:"#{part}").must_equal "#{part}", "With #{n.inspect} for ##{part} method"
          name.send(:"#{part}_quoted").must_equal "[#{part}]", "With #{n.inspect} for ##{part}_quoted method"
        end
        blank.each do |n|
          name = SQLServer::Utils.extract_identifiers(n)
          name.send(:"#{part}").must_be_nil "With #{n.inspect} for ##{part} method"
          name.send(:"#{part}_quoted").must_be_nil "With #{n.inspect} for ##{part}_quoted method"
        end
      end

    end

    it 'does not blow up on nil or blank string name' do
      SQLServer::Utils.extract_identifiers(nil).object.must_be_nil
      SQLServer::Utils.extract_identifiers(' ').object.must_be_nil
    end

    it 'has a #quoted that returns a fully quoted name with all identifiers as orginially passed in' do
      SQLServer::Utils.extract_identifiers('object').quoted.must_equal '[object]'
      SQLServer::Utils.extract_identifiers('server.database..object').quoted.must_equal '[server].[database]..[object]'
      SQLServer::Utils.extract_identifiers('[server]...[object]').quoted.must_equal '[server]...[object]'
    end

    it 'can take a symbol argument' do
      SQLServer::Utils.extract_identifiers(:object).object.must_equal 'object'
    end

    it 'allows identifiers with periods to work' do
      SQLServer::Utils.extract_identifiers('[obj.name]').quoted.must_equal '[obj.name]'
      SQLServer::Utils.extract_identifiers('[obj.name].[foo]').quoted.must_equal '[obj.name].[foo]'
    end

  end

end
