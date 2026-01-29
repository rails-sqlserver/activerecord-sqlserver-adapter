require 'guard/compat/plugin'

module Guard
  class Minitest < Plugin
    require 'guard/minitest/runner'
    require 'guard/minitest/utils'
    require 'guard/minitest/version'

    attr_accessor :runner

    def initialize(options = {})
      super
      @options = {
        all_on_start: true
      }.merge(options)
      @runner  = Runner.new(@options)
    end

    def start
      Compat::UI.info "Guard::Minitest #{MinitestVersion::VERSION} is running, with Minitest::Unit #{Utils.minitest_version}!"
      run_all if @options[:all_on_start]
    end

    def stop
      true
    end

    def reload
      true
    end

    def run_all
      throw_on_failed_tests { runner.run_all }
    end

    def run_on_modifications(paths = [])
      throw_on_failed_tests { runner.run_on_modifications(paths) }
    end

    def run_on_additions(paths)
      runner.run_on_additions(paths)
    end

    def run_on_removals(paths)
      runner.run_on_removals(paths)
    end

    private

    def throw_on_failed_tests
      throw :task_has_failed unless yield
    end
  end
end
