require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

# Notes for cross compile:
# $ gcla ; bundle install ; rake compile ; rake cross compile ; rake cross native gem

def test_libs(mode='dblib')
  ['lib',
   'test',
   "test/connections/native_sqlserver#{mode == 'adonet' ? '' : "_#{mode}"}",
   "#{ENV['RAILS_SOURCE']}/activerecord/test"]
end

def test_files
  files = Dir.glob("test/cases/**/*_test_sqlserver.rb").sort
  unless ENV['ACTIVERECORD_UNITTEST_SKIP']
    ar_cases = Dir.glob("#{ENV['RAILS_SOURCE']}/activerecord/test/cases/**/*_test.rb")
    adapter_cases = Dir.glob("#{ENV['RAILS_SOURCE']}/activerecord/test/cases/adapters/**/*_test.rb")
    files << (ar_cases-adapter_cases).sort
  end
  files
end


task :test => ['test:dblib']
task :default => [:test]

namespace :test do
  
  ['dblib','odbc','adonet'].each do |mode|
    
    Rake::TestTask.new(mode) do |t|
      t.libs = test_libs(mode)
      t.test_files = test_files
      t.verbose = true
    end
    
  end

  namespace :mirroring do 
    
    ['dblib','odbc'].each do |mode|
      Rake::TestTask.new("#{mode}") do |t|
        t.libs = test_libs(mode)
        t.test_files = Dir.glob("test/cases/**/#{mode}_mirroring_test.rb")
        t.verbose = true
      end
    end
    
  end

end


namespace :profile do
  
  ['dblib','odbc','adonet'].each do |mode|
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


