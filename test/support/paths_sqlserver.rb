module ARTest
  module Sqlserver

    extend self

    def test_root_sqlserver
      @test_root_sqlserver ||= begin
        root = File.join File.dirname(__FILE__), '..'
        File.expand_path(root)
      end
    end

    def test_root_activerecord
      @test_root_activerecord ||= begin
        gem_root = Gem.loaded_specs['activerecord'].full_gem_path
        File.join gem_root, 'test'
      end
    end

    def test_root_activerecord_add_to_load_path
      return if $LOAD_PATH.include? test_root_activerecord
      $LOAD_PATH.unshift(test_root_activerecord)
    end

    def migrations_root
      @migrations_root ||= File.join test_root_sqlserver, 'migrations'
    end

    def arconfig_file
      @arconfig_file ||= File.join test_root_sqlserver, 'config.yml'
    end

    def arconfig_file_env!
      ENV['ARCONFIG'] = ARTest::Sqlserver.arconfig_file
    end

  end
end

ARTest::Sqlserver.test_root_activerecord_add_to_load_path
ARTest::Sqlserver.arconfig_file_env!
