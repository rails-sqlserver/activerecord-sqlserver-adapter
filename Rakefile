require 'rake'
require 'rake/testtask'

# Notes for cross compile:
# $ gcla ; bundle install ; rake compile ; rake cross compile ; rake cross native gem

def test_libs(mode='dblib')
  ['lib',
   'test',
   "#{File.join(Gem.loaded_specs['activerecord'].full_gem_path,'test')}"]
end

def test_files
  return ENV['TEST_FILES'].split(',') if ENV['TEST_FILES']
  files = Dir.glob("test/cases/**/*_test_sqlserver.rb").sort
  ar_path = Gem.loaded_specs['activerecord'].full_gem_path
  ar_cases = Dir.glob("#{ar_path}/test/cases/**/*_test.rb")
  adapter_cases = Dir.glob("#{ar_path}/test/cases/adapters/**/*_test.rb")
  files += (ar_cases-adapter_cases).sort
  files
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


