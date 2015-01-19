module ARTest
  module SQLServer

    extend self

    def schema_root
      File.join ARTest::SQLServer.test_root_sqlserver, 'schema'
    end

    def schema_file
      File.join schema_root, 'sqlserver_specific_schema.rb'
    end

    def schema_datatypes_2012_file
      File.join schema_root, 'datatypes', '2012.sql'
    end

    def load_schema
      original_stdout = $stdout
      $stdout = StringIO.new
      load schema_file
    ensure
      $stdout = original_stdout
    end

  end
end

ARTest::SQLServer.load_schema
