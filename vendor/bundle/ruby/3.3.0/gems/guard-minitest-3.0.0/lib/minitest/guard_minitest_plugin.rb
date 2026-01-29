module Minitest
  def self.plugin_guard_minitest_options(opts, options) # :nodoc:
    opts.on '--guard', 'Run with guard plugin enabled' do
      options[:guard] = true
    end
  end

  def self.plugin_guard_minitest_init(options) # :nodoc:
    return unless options[:guard]

    require 'guard/minitest/utils'

    # Require guard unless we're using guard-minitest to test a guard plugin
    require 'guard' unless Dir['guard-*.gemspec'].any?

    require 'guard/minitest/reporter'

    reporter << ::Guard::Minitest::Reporter.new
  end
end
