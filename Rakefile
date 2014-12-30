require 'rake'
require 'rake/testtask'

AR_PATH = Gem.loaded_specs['activerecord'].full_gem_path

# Since the Gemfile for this project requires, rails, it ends up causing
# Rails.env to be defined, which affects some of the unit tests. We fix this
# by setting the RAILS_ENV to "default_env"
ENV['RAILS_ENV'] = 'default_env'

def test_libs
  ar_lib = File.join AR_PATH, 'lib'
  ar_test = File.join AR_PATH, 'test'
  ['lib', 'test', ar_lib, ar_test]
end

def test_files
  test_setup = ['test/cases/sqlserver_helper.rb']
  return test_setup + (ENV['TEST_FILES']).split(',') if ENV['TEST_FILES']
  sqlserver_cases = Dir.glob('test/cases/**/*_test_sqlserver.rb')
  ar_cases = Dir.glob("#{AR_PATH}/test/cases/**/*_test.rb")
  adapter_cases = Dir.glob("#{AR_PATH}/test/cases/adapters/**/*_test.rb")
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
