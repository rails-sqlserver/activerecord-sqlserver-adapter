
require_relative 'test/support/paths_sqlserver'

clearing :on
notification :terminal_notifier if defined?(TerminalNotifier)
ignore %r{debug\.log}

ar_lib  = File.join ARTest::SQLServer.root_activerecord, 'lib'
ar_test = File.join ARTest::SQLServer.root_activerecord, 'test'

guard :minitest, {
  all_on_start: false,
  autorun: false,
  include: ['lib', 'test', ar_lib, ar_test],
  test_folders: ['test'],
  test_file_patterns: ["*_test.rb", "*_test_sqlserver.rb"]
} do
  # Our project watchers.
  if ENV['TEST_FILES']
    ENV['TEST_FILES'].split(',').map(&:strip).each do |file|
      watch(%r{.*}) { file }
    end
  else
    watch(%r{^test/cases/\w+_test_sqlserver\.rb$})
    watch(%r{^test/cases/coerced_tests\.rb$}) { "test/cases/coerced_tests.rb" }
    watch(%r{^lib/active_record/connection_adapters/sqlserver/([^/]+)\.rb$})  { |m| "test/cases/#{m[1]}_test_sqlserver.rb" }
    watch(%r{^test/cases/helper_sqlserver\.rb$}) { 'test' }
  end
end
