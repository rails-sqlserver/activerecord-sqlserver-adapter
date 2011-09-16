require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'


def test_libs(mode='dblib')
  ['lib',
   'test',
   "#{ENV['RAILS_SOURCE']}/activerecord/test"]
end

def test_files
  Dir.glob("test/cases/**/*_test_sqlserver.rb").sort + 
  (Dir.glob("#{ENV['RAILS_SOURCE']}/activerecord/test/cases/**/*_test.rb") - 
   Dir.glob("#{ENV['RAILS_SOURCE']}/activerecord/test/cases/adapters/**/*_test.rb")).sort
end


task :test => ['test:dblib']


namespace :test do
  
  ['dblib','odbc'].each do |mode|
    
    Rake::TestTask.new(mode) do |t|
      t.libs = test_libs(mode)
      t.test_files = test_files
      t.verbose = true
    end
    
    task 'dblib:env' do
      ENV['ARCONN'] = 'dblib'
    end

    task 'odbc:env' do 
      ENV['ARCONN'] = 'odbc'
    end
    
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


