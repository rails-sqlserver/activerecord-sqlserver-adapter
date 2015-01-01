require_relative 'test/support/paths_sqlserver'

notification :terminal_notifier if Guard::Notifier::TerminalNotifier.available?

guard :minitest, {
  all_on_start: false,
  autorun: false,
  include: ['lib', 'test', File.join(ARTest::Sqlserver.root_activerecord, 'lib'), File.join(ARTest::Sqlserver.root_activerecord, 'test')],
  test_folders: ['test'],
  test_file_patterns: ["*_test_sqlserver.rb"],
} do
  watch(%r{^test/cases/\w+_test_sqlserver.rb$})
  watch(%r{^lib/active_record/connection_adapters/sqlserver/([^/]+)\.rb$})  { |m| "test/cases/#{m[1]}_test_sqlserver.rb" }
  watch(%r{^test/cases/helper_sqlserver\.rb$}) { 'test' }
end
