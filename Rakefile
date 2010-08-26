require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
begin ; require 'ruby-prof' ; rescue LoadError ; end


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
  
  ['odbc','adonet'].each do |mode|
    
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
  
  ['odbc','adonet'].each do |mode|
    namespace mode.to_sym do
      
      Rake::TestTask.new('connection') do |t|
        t.libs = test_libs(mode)
        t.test_files = ["test/profile/connection.rb"]
        t.verbose = true
      end 
      
    end
  end
  
end if defined?(RubyProf)


namespace :rvm do
  
  RUBIES = {
    'ruby-1.8.6'      => {:alias => 'sqlsvr186', :odbc => '0.99991'},
    'ruby-1.8.7'      => {:alias => 'sqlsvr187', :odbc => '0.99991'},
    'ruby-1.9.1'      => {:alias => 'sqlsvr191', :odbc => '0.99991'},
    'ruby-1.9.2'      => {:alias => 'sqlsvr192', :odbc => '0.99992pre4'},
    'ree-1.8.7'       => {:alias => 'sqlsvrree', :odbc => '0.99991'}
  }
  
  task :setup do
    unless @rvm_setup
      rvm_lib_path = "#{`echo $rvm_path`.strip}/lib"
      $LOAD_PATH.unshift(rvm_lib_path) unless $LOAD_PATH.include?(rvm_lib_path)
      require 'rvm'
      require 'tmpdir'
      @rvm_setup = true
    end
  end
  
  desc "Shows the command to run tests on all rubie versions."
  task :test => :setup do
    rubies = RUBIES.map { |rubie, info| info[:alias] }
    puts "Run this:\nrvm #{rubies.join(',')} rake test"
  end
  
  task :wipe => :setup do
    rvm_rubies.each { |rubie| RVM.remove(rubie,:gems=>true) }
    RVM.cleanup_all
  end
  
  namespace :install do
    
    desc "Install the following rubie versions if not already: #{RUBIES.keys.inspect}"
    task :rubies => :setup do
      installed_rubies = RVM.list_strings
      RUBIES.keys.each do |rubie|
        if installed_rubies.any? { |ir| ir =~ /#{rubie}/ }
          puts "info: Rubie #{rubie} already installed."
        else
          with_my_environment_vars do
            good_msg = "info: Rubie #{rubie} installed."
            bad_msg = "Failed #{rubie} install! Check RVM logs here: #{RVM.path}/log/#{rubie}"
            puts "info: Rubie #{rubie} installation inprogress. This could take awhile..."
            RVM.install(rubie,rvm_install_options) ? puts(good_msg) : abort(bad_msg)
          end
        end
      end
      rvm_each_rubie do
        RVM.gemset_create rvm_gemset_name
        RVM.alias_create rvm_current_rubie_info[:alias], rvm_current_name
      end
    end
    
    desc "Install ruby-odbc for each rubie version."
    task :odbc => :setup do
      rvm_each_rubie do
        odbc = "ruby-odbc-#{rvm_current_rubie_info[:odbc]}"
        RVM.chdir(Dir.tmpdir) do
          RVM.run "rm -rf #{odbc}*"
          puts "info: RubyODBC downloading #{odbc}..."
          RVM.run "curl -O http://www.ch-werner.de/rubyodbc/#{odbc}.tar.gz"
          puts "info: RubyODBC extracting clean work directory..."
          RVM.run "tar -xf #{odbc}.tar.gz"
          ['ext','ext/utf8'].each do |extdir|
            RVM.chdir("#{odbc}/#{extdir}") do
              puts "info: RubyODBC configuring in #{extdir}..."
              RVM.ruby 'extconf.rb', "--with-odbc-dir=#{rvm_odbc_dir}"
              puts "info: RubyODBC make and installing for #{rvm_current_name}..."
              RVM.run "make && make install"
            end
          end
        end
      end
    end
    
    desc "Install development gems using bundler to each rubie version, installing bundler if not already."
    task :bundle => :setup do
      rvm_each_rubie(:gemset => 'global') { rvm_install_gem 'bundler', '1.0.0.rc.6' }
      rvm_each_rubie { RVM.run 'bundle install' }
    end
    
  end
  
end



# RVM Helper Methods

def rvm_each_rubie(options={})
  rvm_rubies(options).each do |rubie|
    RVM.use(rubie)
    yield
  end
ensure
  RVM.reset_current!
end

def rvm_rubies(options={})
  gemset = options[:gemset] || rvm_gemset_name
  RUBIES.keys.map{ |rubie| "#{rubie}@#{gemset}" }
end

def rvm_current_rubie_info
  key = rvm_current_rubie_name
  while !key.empty?
    info = RUBIES[key]
    return info if info
    new_key = key.split('-') ; new_key.pop
    key = new_key.join('-')
  end
end

def rvm_current_rubie_name
  rvm_current_name.sub("@#{rvm_gemset_name}",'')
end

def rvm_current_name
  RVM.current.expanded_name
end

def rvm_gemset_name
  'sqlserver'
end

def rvm_with_macports?
  `uname`.strip == 'Darwin' && !`which port`.empty?
end

def rvm_install_options
  {}
end

def rvm_odbc_dir
  rvm_with_macports? ? '/opt/local' : '/usr/local'
end

def rvm_gem_available?(*specs)
  available_args = specs.map{ |s| "'#{s}'" }.join(',')
  RVM.ruby_eval("require 'rubygems' ; print Gem.available?(#{available_args})").stdout == 'true'
end

def rvm_install_gem(*specs)
  gem, version = specs
  spec_info = specs.join(', ')
  if rvm_gem_available?(*specs)
    puts "info: Gem #{spec_info} already installed in #{rvm_current_name}."
  else
    puts "info: Installing gem #{spec_info} in #{rvm_current_name}..."
    install_args = [:gem, 'install', gem]
    install_args += ['-v', version] if version && !version.empty?
    puts RVM.perform_set_operation(*install_args).stdout
  end
end

def with_my_environment_vars
  my_vars = my_environment_vars
  current_vars = my_vars.inject({}) { |cvars,kv| k,v = kv ; cvars[k] = ENV[k] ; cvars }
  set_environment_vars(my_vars)
  yield
ensure
  set_environment_vars(current_vars)
end

def my_environment_vars
  if rvm_with_macports?
    { 'CC' => '/usr/bin/gcc-4.2',
      'CFLAGS' => '-O2 -arch x86_64',
      'LDFLAGS' => '-L/opt/local/lib -arch x86_64',
      'CPPFLAGS' => '-I/opt/local/include' }
  else
    {}
  end
end

def set_environment_vars(vars)
  vars.each { |k,v| ENV[k] = v }
end


