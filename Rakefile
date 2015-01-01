require 'rake/testtask'
require_relative 'test/support/paths_sqlserver'

def test_libs
  ar_lib = File.join ARTest::Sqlserver.root_activerecord, 'lib'
  ar_test = File.join ARTest::Sqlserver.root_activerecord, 'test'
  ['lib', 'test', ar_lib, ar_test]
end

def test_files
  test_setup = ['test/cases/helper_sqlserver.rb']
  return test_setup + (ENV['TEST_FILES']).split(',') if ENV['TEST_FILES']
  sqlserver_cases = Dir.glob('test/cases/**/*_test_sqlserver.rb')
  ar_cases = Dir.glob("#{ARTest::Sqlserver.root_activerecord}/test/cases/**/*_test.rb")
  adapter_cases = Dir.glob("#{ARTest::Sqlserver.root_activerecord}/test/cases/adapters/**/*_test.rb")
  if ENV['SQLSERVER_ONLY']
    sqlserver_cases
  elsif ENV['ACTIVERECORD_ONLY']
    test_setup + (ar_cases - adapter_cases)
  else
    test_setup + sqlserver_cases + (ar_cases - adapter_cases)
  end
end

task test: ['test:dblib']
task default: [:test]

namespace :test do

  %w(dblib odbc).each do |mode|

    Rake::TestTask.new(mode) do |t|
      t.libs = test_libs
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
          t.libs = test_libs
          t.test_files = [test_file]
          t.verbose = true
        end
      end
    end
  end
end
