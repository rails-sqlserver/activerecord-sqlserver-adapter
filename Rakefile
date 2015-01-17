require 'rake/testtask'
require_relative 'test/support/paths_sqlserver'

def test_files
  if files = ENV['AR_TEST_FILES']
    files = files.split(',').map do |file|
      File.join ARTest::SQLServer.root_activerecord, file.strip
    end
    return files.unshift 'test/cases/helper_sqlserver.rb'
  end
  if files = ENV['TEST_FILES']
    return files.split(',').map(&:strip)
  end
  sqlserver_cases = Dir.glob('test/cases/**/*_test_sqlserver.rb')
  ar_cases = Dir.glob("#{ARTest::SQLServer.root_activerecord}/test/cases/**/*_test.rb")
  if ENV['SQLSERVER_ONLY']
    sqlserver_cases
  elsif ENV['ACTIVERECORD_ONLY']
    ar_cases
  else
    sqlserver_cases + ar_cases
  end
end

task test: ['test:dblib']
task default: [:test]

namespace :test do

  %w(dblib odbc).each do |mode|

    Rake::TestTask.new(mode) do |t|
      t.libs = ARTest::SQLServer.test_load_paths
      t.test_files = test_files
      t.verbose = true
    end

  end

  task 'dblib:env' do
    ENV['ARCONN'] = 'dblib'
  end

  task 'odbc:env' do
    ENV['ARCONN'] = 'odbc'
  end

end

task 'test:dblib' => 'test:dblib:env'
task 'test:odbc' => 'test:odbc:env'

namespace :profile do
  ['dblib', 'odbc'].each do |mode|
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
