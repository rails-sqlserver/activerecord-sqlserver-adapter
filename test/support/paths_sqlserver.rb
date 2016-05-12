module ARTest
  module SQLServer

    extend self

    def root_sqlserver
      File.expand_path File.join(File.dirname(__FILE__), '..', '..')
    end

    def test_root_sqlserver
      File.join root_sqlserver, 'test'
    end

    def root_activerecord
      File.join Gem.loaded_specs['rails'].full_gem_path, 'activerecord'
    end

    def root_activerecord_lib
      File.join root_activerecord, 'lib'
    end

    def root_activerecord_test
      File.join root_activerecord, 'test'
    end

    def test_load_paths
      ['lib', 'test', root_activerecord_lib, root_activerecord_test]
    end

    def add_to_load_paths!
      test_load_paths.each { |p| $LOAD_PATH.unshift(p) unless $LOAD_PATH.include?(p) }
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

ARTest::SQLServer.add_to_load_paths!
ARTest::SQLServer.arconfig_file_env!
