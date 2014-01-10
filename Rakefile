require 'rake'
require 'rake/testtask'

AR_PATH   = Gem.loaded_specs['activerecord'].full_gem_path
AREL_PATH = Gem.loaded_specs['arel'].full_gem_path
# Notes for cross compile:
# $ gcla ; bundle install ; rake compile ; rake cross compile ; rake cross native gem

def test_libs(mode='dblib')
  ['lib',
   'test',
   "#{File.join(AR_PATH,'test')}",
   "#{File.join(AREL_PATH,'test')}",
 ]
end

# bundle exec rake test SQLSERVER_ONLY=true
# 
# If you have trouble running single tests (errors about requirements):
# http://veganswithtypewriters.net/blog/2013/06/29/weirdness-with-rake-solved/
def test_files
  test_setup = ["test/cases/sqlserver_helper.rb"]

  return test_setup + (ENV['TEST_FILES']).split(',') if ENV['TEST_FILES']
  
  sqlserver_cases = Dir.glob("test/cases/**/*_test_sqlserver.rb")
  
  ar_cases = Dir.glob("#{AR_PATH}/test/cases/**/*_test.rb")
  adapter_cases = Dir.glob("#{AR_PATH}/test/cases/adapters/**/*_test.rb")

  arel_cases = Dir.glob("#{AREL_PATH}/test/**/test_*.rb")

  if ENV['SQLSERVER_ONLY']
    sqlserver_cases
  elsif ENV['ACTIVERECORD_ONLY']
    test_setup + (ar_cases - adapter_cases)
  elsif ENV['AREL_ONLY']
    arel_cases
  else
    test_setup + arel_cases + sqlserver_cases + (ar_cases - adapter_cases)
  end
  
end

task :test => ['test:dblib']
task :default => [:test]


namespace :test do
  
  ['dblib','odbc'].each do |mode|
    
    Rake::TestTask.new(mode) do |t|
      t.libs = test_libs(mode)
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
  
  ['dblib','odbc'].each do |mode|
    namespace mode.to_sym do
      
      Dir.glob("test/profile/*_profile_case.rb").sort.each do |test_file|
        
        profile_case = File.basename(test_file).sub('_profile_case.rb','')
        
        Rake::TestTask.new(profile_case) do |t|
          t.libs = test_libs(mode)
          t.test_files = [test_file]
          t.verbose = true
        end
        
      end
      
    end
  end
  
end
