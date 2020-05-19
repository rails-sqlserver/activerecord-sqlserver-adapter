As of 2.3.6 of the adapter, we are now compliant with the rake task interfaces in the :db namespace of rails. That means for new unix-based developers that are working with a non-legacy DB, accurately reflected by schema.rb, can now use the standard rake tasks for just about everything except actually creating the development/test databases. 

The only problem is that the we have not yet committed patches upstream to rails to remove Windows specific command interpolation from their databases.rake task. So, we have to do two things to get you up and running. First, here is an extension to Rake that allows us to method chain tasks.

**FYI, the AdventureWorks.Ruby project has a great example of this process.**
"https://github.com/rails-sqlserver/AdventureWorks.Ruby":https://github.com/rails-sqlserver/AdventureWorks.Ruby

<script src="http://gist.github.com/414494.js"></script>
```ruby
    # Place this in your rails lib directory and require in your Rakefile.

    Rake::TaskManager.class_eval do
      def alias_task(fq_name)
        new_name = "#{fq_name}:original"
        @tasks[new_name] = @tasks.delete(fq_name)
      end
    end

    def alias_task(fq_name)
      Rake.application.alias_task(fq_name)
    end

    def alias_task_chain(*args, &block)
      name, params, deps = Rake.application.resolve_args(args.dup)
      fq_name = Rake.application.instance_variable_get(:@scope).dup.push(name).join(':')
      alias_task(fq_name)
      Rake::Task.define_task(*args, &block)
    end
```

Next, here are the overrides for each task in a default rails application. Some notes about them – first, we are not supporting any native SQL structure dump. No scptxfr or anything like that. Because we have a mixed dev community these are left blank. The override rake task finally allows you to build your own platform specific task now without rails core task blowing up on us. The main task is db:test:purge. We now use our own #recreate_database method which basically just removes all the tables prior to a schema load. If the database is not there and/or an exception is raised, it calls #recreate_database! with the database name from your configuration. The bang method will attempt to create your database. Hopefully the connection user has perms for this.

<script src="http://gist.github.com/414499.js"></script>
```ruby
    # Place this in lib/tasks

    namespace :db do
  
      alias_task_chain :charset => :environment do
        config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
        case config['adapter']
        when 'sqlserver'
          ActiveRecord::Base.establish_connection(config)
          puts ActiveRecord::Base.connection.charset
        else
          Rake::Task["db:charset:original"].execute
        end
      end
  
      namespace :structure do
    
        alias_task_chain :dump => :environment do
          if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] != "sqlserver"
            Rake::Task["db:structure:dump:original"].execute
          end
        end
    
      end
  
      namespace :test do
    
        alias_task_chain :clone_structure => [ "db:structure:dump", "db:test:purge" ] do
          if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] != "sqlserver"
            Rake::Task["db:test:clone_structure:original"].execute
          end
        end
    
        alias_task_chain :purge => :environment do
          abcs = ActiveRecord::Base.configurations
          case abcs["test"]["adapter"]
          when "sqlserver"
            ActiveRecord::Base.establish_connection(:test)
            begin
              ActiveRecord::Base.connection.recreate_database
            rescue
              ActiveRecord::Base.connection.recreate_database!(abcs["test"]["database"])
            end
          else
            Rake::Task["db:test:purge:original"].execute
          end
        end

      end

    end
```

h2. An Example That Clones A Legacy Database For Testing.

I use this on my SQL Server 2000 database to clone a legacy database that can not be represented by the schema.rb due to views, stored procedures, and many other things. This solution assumes two important things. First that you are developing your rails application from a unix'y system, who doesn't? Second that you have taken the time to instally Cygwin and OpenSSH on your target development Windows database box. I wont even cover that topic, consult your local Google index. 

OK, assuming that is done, here is the new databases.rake task. A few key points about it. It uses Net::SSH to open a connection to your windows box and assumes osql and scptxfr are installed on your box and in the Cygwin path. Using these commands it dump a series of files used to create the structure of the database. If you have custom file groups (these do not play well with test dbs, customize the #my_db_filegroups method. When importing the structure into a new "..._test" database, it will remove foreign key constraints. Finally it will copy the schema migrations over from development. This way running "rake test" will only clone the db if needed, since this can be a lengthy process, 2-5 minutes depending on your legacy DB size.

<script src="http://gist.github.com/526020.js"></script>
```ruby
    require 'tasks/alias_task_chain'

    namespace :db do

      alias_task_chain :charset => :environment do
        config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
        case config['adapter']
        when 'sqlserver'
          ActiveRecord::Base.establish_connection(config)
          puts ActiveRecord::Base.connection.charset
        else
          Rake::Task["db:charset:original"].execute
        end
      end

      namespace :schema do

        alias_task_chain :load => :environment do
          if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] == "sqlserver"
            puts 'Task db:schema:load skipped for SQL Server.'
          else
            Rake::Task["db:schema:load:original"].execute
          end
        end

      end

      namespace :structure do

        alias_task_chain :dump => :environment do
          if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] == "sqlserver"
            Rake::Task["db:myproject:structure:dump"].execute
          else
            Rake::Task["db:structure:dump:original"].execute
          end
        end

      end

      namespace :test do

        desc "Force recreate the test databases from the development structure"
        task :clone_force => :environment do
          force_test_database_needs_migrations { Rake::Task["db:test:clone"].execute }
        end

        alias_task_chain :clone => :environment do
          if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] == "sqlserver"
            Rake::Task["db:myproject:structure:dump"].execute
            Rake::Task["db:myproject:test:clone_structure"].execute
          else
            Rake::Task["db:test:clone:original"].execute
          end
        end

        alias_task_chain :clone_structure => "db:structure:dump" do
          if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] == "sqlserver"
            Rake::Task["db:myproject:test:clone_structure"].execute
          else
            Rake::Task["db:test:clone_structure:original"].execute
          end
        end

        alias_task_chain :purge => :environment do
          if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] == "sqlserver"
            puts 'Task db:test:purge skipped for SQL Server.'
          else
            Rake::Task["db:test:purge:original"].execute
          end
        end

      end

      namespace :myproject do

        namespace :structure do

          task :setup_remote_dirs => :environment do
            with_db_server_connection do |ssh|
              ssh.exec! "rm -rf #{structure_dirs}"
              ssh.exec! "mkdir -p #{structure_dirs}"
            end
          end

          task :dump => [:environment, :setup_remote_dirs] do
            with_db_server_connection do |ssh|
              puts "-- Dropping and/or creating a new #{database_name(:test => true)} DB..."
              ssh.exec! "osql -E -S #{osql_scptxfr_host} -d master -Q 'DROP DATABASE #{database_name(:test => true)}'"
              ssh.exec! "osql -E -S #{osql_scptxfr_host} -d master -Q 'CREATE DATABASE #{database_name(:test => true)}'"
              puts "-- Dumping #{database_name} structure from remote DB into remote #{structure_dirs} directory..."
              ssh.exec! "scptxfr /s #{osql_scptxfr_host} /d #{database_name} /I /f #{structure_filepath} /q /A /r"
              ssh.exec! "scptxfr /s #{osql_scptxfr_host} /d #{database_name} /I /F #{structure_dirs}/ /q /A /r"
              puts "-- Chainging all custom filegroups from #{structure_filepath} to PRIMARY default..."
              sed_command = "sed -r -e 's/ON \\[(#{my_db_filegroups.join('|')})\\]/ON [PRIMARY]/' -i #{structure_filepath}"
              ssh.exec!(sed_command)
              puts "-- Removing all TEXTIMAGE_ON filegroups from #{structure_filepath}..."
              sed_command = "sed -r -e 's/TEXTIMAGE_ON \\[PRIMARY\\]//' -i #{structure_filepath}"
              ssh.exec!(sed_command)
              puts "-- Changing all DB names to test DBs in #{structure_filepath}..."
              sed_command = "sed -r -e 's/#{database_name}/#{database_name(:test => true)}/g' -i #{structure_filepath}"
              ssh.exec!(sed_command)
            end if test_database_needs_migrations?
          end

        end

        namespace :test do

          task :clone_structure => :environment do
            @close_db_server_connection = true
            with_db_server_connection do |ssh|
              puts "-- Importing clean structure into #{database_name(:test => true)} DB..."
              dropfkscript = "#{database_host.upcase}.#{database_name}.DP1".gsub(/\\/,'-')
              ssh.exec! "osql -E -S #{osql_scptxfr_host} -d #{database_name(:test => true)} -i #{structure_dirs}/#{dropfkscript}"
              ssh.exec! "osql -E -S #{osql_scptxfr_host} -d #{database_name(:test => true)} -i #{structure_filepath}"
              puts "-- Removing foreign key constraints #{database_name(:test => true)}..."
              ssh.exec! "osql -E -S #{osql_scptxfr_host} -d #{database_name(:test => true)} -i #{structure_dirs}/#{dropfkscript}"
              copy_schema_migrations
            end if test_database_needs_migrations?
          end

        end

      end

    end




    def database_name(options={})
      suffix = options[:test] ? '_test' : ''
      "MyProjectDb#{suffix}"
    end

    def database_host
      ENV['MYPROJECT_DEVDB_HOST']
    end

    def database_user
      ENV['MYPROJECT_DEVDB_USER']
    end

    def with_db_server_connection
      require 'net/ssh' unless defined? Net::SSH
      @database_connection ||= Net::SSH.start(database_host, database_user, :verbose => :fatal)
      yield(@database_connection)
      @database_connection.close if @close_db_server_connection
    end

    def test_database_needs_migrations?
      return true if @force_test_database_needs_migrations
      return @test_database_needs_migrations unless @test_database_needs_migrations.nil?
      ActiveRecord::Base.establish_connection(:test)
      @test_database_needs_migrations = ActiveRecord::Migrator.new(:up,'db/migrate').pending_migrations.present?
    end

    def force_test_database_needs_migrations
      @force_test_database_needs_migrations = true
      yield
    ensure
      @force_test_database_needs_migrations = false
    end

    def osql_scptxfr_host
      'localhost'
    end

    def structure_filepath
      "#{structure_dirs}/#{RAILS_ENV}_structure.sql"
    end

    def structure_dirs
      "db/myproject"
    end

    def my_db_filegroups
      ['FOO_DATA','BAR_DATA']
    end

    def copy_schema_migrations
      schema_table = ActiveRecord::Migrator.schema_migrations_table_name
      ActiveRecord::Base.establish_connection(:development)
      versions = ActiveRecord::Base.connection.select_values("SELECT version FROM #{schema_table}").map(&:to_i).sort
      ActiveRecord::Base.establish_connection(:test)
      puts "-- Copying Schema Migrations..."
      versions.each do |version|
        ActiveRecord::Base.connection.insert("INSERT INTO #{schema_table} (version) VALUES ('#{version}')")
      end
    end 
```

h2. Settings up a Cygwin SSH server

There are a bunch of places on the web describing how to install a Cygwin SSH server, but here's a quick rundown of what you need to do. 

# Download the Cygwin installer: "http://www.cygwin.com/setup.exe":http://www.cygwin.com/setup.exe
# Install the openssh package. 
# After the install is finished, open up a Cygwin command prompt and type:
 @ssh-host-config@
# You'll answer yes to all of the prompts (I think)
# Start the sshd service by running: 
 @net start sshd@

h2. SQL Server 2005/2008 testing

The scptxfr utility used above by Ken is only provided with SQL Server 2000. If you're using 2005/2008, I suggest you use SMOscript. It's one of the only utilities I've found that provides the same scptxfr-like functionality that we need for cloning our DB structure when testing.

You can download SMOscript at: "http://www.devio.at/index.php/smoscript":http://www.devio.at/index.php/smoscript

I suggest putting SMOscript in your PATH, and modifying the above 2 scptxfr references to instead be:
@ssh.exec! "smoscript -s #{osql_scptxfr_host} -d #{database_name} -f #{structure_filepath}"@