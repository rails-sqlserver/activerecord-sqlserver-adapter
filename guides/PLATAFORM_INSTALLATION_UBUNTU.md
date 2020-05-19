## TinyTDS Note

Current versions of the adapter use TinyTDS rendering much of this documentation obsolete.  You can still follow this guide but should be able to skip the Unix ODBC sections.  Then look at [[Using TinyTDS]] for more info.

## Configure SQL Server 2008

By default the server does not listen on a TCP port. Enable it following
these "instructions.":http://msdn.microsoft.com/en-us/library/bb909712.aspx

## FreeTDS

This package implements the TDS protocol between SQL Server and the Ubuntu box.
The Ubuntu packages for this are:

@sudo apt-get install freetds-dev freetds-bin tdsodbc@

## UnixODBC

This package implements and ODBC layer over FreeTDS The Ubuntu packages for
this are:

@sudo apt-get install unixodbc unixodbc-dev@

## Configure FreeTDS

FreeTDS needs a configuration file named /etc/freetds/freetds.conf.

The example below has two entries. The first entry, [developer], tells FreeTDS how to
connect to a named SQL Server 2008 instance named DEVELOPER.

The second entry, [production], tells FreeTDS how to connect to the default SQL Server
instance. In this case no 'instance' parameter is required.

<pre>
[developer]
  host = endor
  port = 1433
  instance = DEVELOPER # connect to a named instance
  tds version = 8.0
  client charset = UTF-8

[production]
  host = endor
  port = 1433
  tds version = 8.0
  client charset = UTF-8
</pre>

## Test FreeTDS

Use the command line client sqsh to test your FreeTDS configuration.

@sudo apt-get install sqsh@

For example, to connect to the developer database and perform a count on the people
table do this:

@sqsh -S developer -U database_username -P database_password@

A sqsh prompt should open up.
<pre>
> use project_development
> go
> select count(*) from people
> go
</pre>

You should see the result of the count.

## Configure UnixODBC

Tell UnixODBC where the FreeTDS driver is. In /etc/odbcinst.ini put the
following:

<pre>
[FreeTDS]
Description     = TDS driver (Sybase/MS SQL)
Driver          = /usr/lib/odbc/libtdsodbc.so
Setup           = /usr/lib/odbc/libtdsS.so
CPTimeout       =
CPReuse         =
FileUsage       = 1
</pre>

or
Ubuntu after to 12.04 has a different odbc path.
<pre>
[FreeTDS]
Description     = TDS driver (Sybase/MS SQL)
Driver = /usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so
Setup = /usr/lib/x86_64-linux-gnu/odbc/libtdsS.so
CPTimeout       =
CPReuse         =
FileUsage       = 1
</pre>
## Create the ODBC entries for you databases

ODBC DSN entries are defined in /etc/odbc.ini.

Note that the names you give these entries are the names you'll use in your
rails database.yml file.

The template for an odbc.ini entry is:

<pre>
[dsn] #this is the name you use for the 'dsn' field in your rails database.yml
Driver = FreeTDS
Description = ODBC connection via FreeTDS
Trace = No
Servername = myserver # This is the name of an entry in your /etc/freetds/freetds.conf file
Database = actual_database_name # This is the name of a database in your SQL Server instance.
</pre>

My /etc/odbc.ini looks like this:

<pre>
[project_development]
Driver = FreeTDS
Description     = ODBC connection via FreeTDS
Trace           = No
Servername      = developer
Database        = project_development

[project_test]
Driver = FreeTDS
Description = ODBC connection via FreeTDS
Trace = No
Servername = developer
Database = test

[project_production]
Driver = FreeTDS
Description = ODBC connection via FreeTDS
Trace = No
Servername = production
Database = project_production
</pre>

## Test UnixODBC

You can test your ODBC configuration with the isql command. For example:

<pre>
isql -v project_development database_username password
SQL> select count(*) from people;
</pre>

returns the count of records in the people table.

## Install ruby-odbc

ruby-odbc is the ruby binding to the UnixODBC library.

h3. Install ruby-odbc from apt

On Ubuntu install the package libodbc-ruby1.8

@sudo apt-get install libodbc-ruby1.8@

h3. Install ruby-odbc from source (when the installation from apt doesn't work)

The ruby-odbc library is available in the apt repository and the version in apt has worked in the past, but if the ruby-odbc layer returns an error like
@ODBC::Error: INTERN (0) [RubyODBC]Cannot allocate SQLHENV@
then try installing from source.

The version in apt is compiled to dynamically load the odbc library at run time. This allows ruby-odbc to pick between the iODBC library and the UnixODBC library. There are cases where ruby-odbc is unable to load the UnixODBC library at run time. This behavior can be changed at compile time.

First remove the apt package if you installed it.
@sudo apt-get remove librubyodbc-ruby1.8@

Get the latest source package from "http://www.ch-werner.de/rubyodbc/":http://www.ch-werner.de/rubyodbc/.

Follow the instructions in the README, using the following command to disable dynamically loading the odbc library at runtime (the --disable-dlopen is the key bit):

@ruby -Cext extconf.rb --disable-dlopen@

h3. Test ruby-odbc using irb
<pre>
irb > require 'odbc'
irb > ODBC.connect("dsn", "username", "password")
</pre>

If you don't get an error ruby-odbc is good to go.

## Install The Rails Adapter

Follow the Installation instructions in the adapter's README, located here:
"README":http://github.com/rails-sqlserver/2000-2005-adapter/tree/master

Scroll down to the "Installation" section.

## Setup your database.yml

The database.yml setup is pretty simple. There is a special case for the 'test'
entry. If your test database name doesn't match the DSN name for that database
you must explicitly set the database name by assigning to the database field.

<pre>
production:
  adapter: sqlserver
  mode: odbc
  dsn: project_production
  username: dbuser
  password: password
  encoding: utf8

development:
  adapter: sqlserver
  mode: odbc
  dsn: project_development
  username: dbuser
  password: password
  encoding: utf8

test:
  adapter: sqlserver
  mode: odbc
  dsn: project_test
  database: test #This must be the real name of the database on the server, not the ODBC DSN! Only required for test.
  username: dbuser
  password: password
  encoding: utf8
</pre>

## Test that the application can talk to the database

Enter the console and query a table using active_record:

<pre>
script/console
> Person.count
</pre>

## One last bit of Rails hackery.

There are several places where Rails' lib/tasks/database.rake assumes it is
installed on windows and calls oslq. The test:purge task does this so you can't
run your tests from Ubuntu. My solution is to simply edit that task in place like this:

<pre>
when "sqlserver"
-        dropfkscript = "#{abcs["test"]["host"]}.#{abcs["test"]["database"]}.DP1".gsub(/\\/,'-')
-        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{dropfkscript}`
-        `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{RAILS_ENV}_structure.sql`
+        ActiveRecord::Base.clear_active_connections!
+        ActiveRecord::Base.connection.recreate_database(abcs["test"]["database"])
when "oci", "oracle"
       ActiveRecord::Base.establish_connection(:test)
</pre>
