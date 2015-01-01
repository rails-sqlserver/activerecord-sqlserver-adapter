module ARTest
  module Sqlserver

    extend self

    def schema_root
      @schema_root ||= File.join ARTest::Sqlserver.test_root_sqlserver, 'schema'
    end

    def schema_file
      @schema_file ||= File.join schema_root, 'sqlserver_specific_schema.rb'
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

ARTest::Sqlserver.load_schema
