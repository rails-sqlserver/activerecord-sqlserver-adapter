require 'bundler/gem_tasks'
require 'rake/testtask'
require_relative 'test/support/paths_sqlserver'
require_relative 'test/support/rake_helpers'

AR_SQL_SERVER_MODE = RUBY_ENGINE == 'jruby' ? 'jdbc' : 'dblib'

task test: ['test:' + AR_SQL_SERVER_MODE]
task default: [:test]

namespace :test do

  Rake::TestTask.new(AR_SQL_SERVER_MODE) do |t|
    t.libs = ARTest::SQLServer.test_load_paths
    t.test_files = test_files
    t.warning = !!ENV['WARNING']
    t.verbose = false
  end

  task 'dblib:env' do
    ENV['ARCONN'] = 'dblib'
  end

  task 'jdbc:env' do
    ENV['ARCONN'] = 'jdbc'
  end

end

task 'test:dblib' => 'test:dblib:env'
task 'test:jdbc' => 'test:jdbc:env'

namespace :profile do
  ['dblib'].each do |mode|
    namespace mode.to_sym do
      Dir.glob('test/profile/*_profile_case.rb').sort.each do |test_file|
        profile_case = File.basename(test_file).sub('_profile_case.rb', '')
        Rake::TestTask.new(profile_case) do |t|
          t.libs = ARTest::SQLServer.test_load_paths
          t.test_files = [test_file]
          t.verbose = true
        end
      end
    end
  end
end
