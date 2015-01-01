module ARTest
  module Sqlserver

    extend self

    def root_sqlserver
      File.expand_path File.join(File.dirname(__FILE__), '..', '..')
    end

    def test_root_sqlserver
      File.join root_sqlserver, 'test'
    end

    def root_activerecord
      Gem.loaded_specs['activerecord'].full_gem_path
    end

    def test_root_activerecord
      File.join root_activerecord, 'test'
    end

    def test_root_activerecord_add_to_load_path
      return if $LOAD_PATH.include? test_root_activerecord
      $LOAD_PATH.unshift(test_root_activerecord)
    end

    def migrations_root
      File.join test_root_sqlserver, 'migrations'
    end

    def arconfig_file
      File.join test_root_sqlserver, 'config.yml'
    end

    def arconfig_file_env!
      ENV['ARCONFIG'] = arconfig_file
    end

  end
end

ARTest::Sqlserver.test_root_activerecord_add_to_load_path
ARTest::Sqlserver.arconfig_file_env!
