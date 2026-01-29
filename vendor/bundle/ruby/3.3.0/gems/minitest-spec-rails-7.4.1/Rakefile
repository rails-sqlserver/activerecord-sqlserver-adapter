require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = %w[lib test]
  t.test_files = Dir.glob('test/**/*_test.rb').sort
  t.verbose = false
  t.warning = false
end

task default: :test
