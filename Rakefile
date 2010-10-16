require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'


def test_libs(mode='odbc')
  ['lib',
   'test',
   "test/connections/native_sqlserver#{mode == 'adonet' ? '' : "_#{mode}"}",
   "#{ENV['RAILS_SOURCE']}/activerecord/test"]
end

def test_files
  Dir.glob("test/cases/**/*_test_sqlserver.rb").sort + 
  (Dir.glob("#{ENV['RAILS_SOURCE']}/activerecord/test/cases/**/*_test.rb") - 
   Dir.glob("#{ENV['RAILS_SOURCE']}/activerecord/test/cases/adapters/**/*_test.rb")).sort
end


task :test => ['test:odbc']


namespace :test do
  
  ['dblib','odbc','adonet'].each do |mode|
    
    Rake::TestTask.new(mode) do |t|
      t.libs = test_libs(mode)
      t.test_files = test_files
      t.verbose = true
    end
    
  end

  desc 'Test without unicode types enabled, uses ODBC mode.'
  task :non_unicode_types do
    ENV['ENABLE_DEFAULT_UNICODE_TYPES'] = 'false'
    test = Rake::Task['test:odbc']
    test.invoke
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


