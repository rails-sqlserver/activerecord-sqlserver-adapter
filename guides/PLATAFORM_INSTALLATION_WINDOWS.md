## Using TinyTDS as connection option (April 2011)

Ken created a wonderful, simple and high-performance alternative to ruby-odbc.
His gem TinyTDS [[https://github.com/rails-sqlserver/tiny_tds]] talks directly to the database server using the TDS protocol eliminating some of the cumbersomeness setting up a connection. Please read the [[ Using TinyTDS ]] page for full details!


## Rails 3, Ruby 1.9.2, Windows 2008, and SQL Server 2008 Tutorial (thanks Xavier Shay, Oct 10, 2010)

"This took me a while to figure out, especially since I’m not so great with either windows or SQL server, but in the end the process isn’t so difficult.":http://rhnh.net/2010/10/10/rails-3-ruby-1-9-2-windows-2008-and-sql-server-2008-tutorial


## Moving From ADO To ODBC (thanks @adamdennis updated May 12 2010)

The following are the versions and settings we have used on Windows 2003 RC2 Server and Windows 2008 x64 Server to connect our Ruby apps to MS SQL Server 2005 and 2008. We were using DBI/ADO but ADO is an arcane beast and we’re are getting better performance out of the ODBC connection. For a while we used DBI/DBD/DBD-ODBC (I just like saying that). Now we just use the excellent activerecord-sqlserver-adapter and the equally good ruby-odbc gem from Christian Werner.
We also deploy our app to Linux boxes that need to use enterprise MS SQL Server databases so this method minimises our deployment problems.

PLEASE NOTE that if you have an older version of RubyDBI installed, you will need to remove it manually before installing the gems below by deleting the following files and folders:
C:\ruby\lib\ruby\site_ruby\1.8\dbi.rb
C:\ruby\lib\ruby\site_ruby\1.8\dbi
C:\ruby\lib\ruby\site_ruby\1.8\DBD

Also remove any sqlserver adapters bundled in your vendor/gems folder (if it has been packed it in).

Windows Gems Required:
gem install ruby-odbc-0.99991.gem
gem install activerecord-sqlserver-adapter 2.3.5

Un*x requirements:
unixODBC 2.x or libiodbc 3.52 on UN*X

Setup your DSN by running odbcad32.exe which is usually under C:\Windows\system32 (see note below).
When setting the ODBC connection up make sure you create a SYSTEM DSN and not a USER DSN:
Name: [used for dsn: in database.yaml]
Description: [same as name?]
Server: [windows name of machine]

Some issues with MS ODBC
- SQL Server 2005 was returning \000 after all big decimals and others. We connect via activerecord-sqlserver-adapter (2.3.5) and use dbd-odbc (0.2.5) and dbi (0.4.4). Finally found the solution tonight. When setting up your ODBC Datasource (DSN) in odbcad32.exe make sure that:
“Perform translation for character data” is OFF.
“Use regional settings when outputting currency, numbers, dates and times” is OFF.
Turning the later one off fixed a lot of problems for us – we were blaming the adapter, but as mentioned above it was the MS ODBC driver trying to be smart.
- On another server we were getting an error “no such file to load — odbc”. Fixed this by changing the “language of the SQL Server system messages to” English (was British English). Once again this is done in odbcad32.exe.

IMPORTANT Windows 2008 Server Info:
The 32-bit version of the Odbcad32.exe file is located in the systemdrive\Windows\SysWoW64 folder.
The 64-bit version of the Odbcad32.exe file is located in the systemdrive\Windows\System32 folder.

Delete any ODBC settings you may have made in the 64bit verison and then access the 32bit version and set up your services as normal

Your app's config/database.yml file::
production:
adapter: sqlserver
mode: ODBC
dsn: [your_database_dsn] (what you name the connection when running odbcad32.exe above)
database: [your_db_name]
host: [windows name of machine]
username: [your_sqlserver_user]
password: [your_sqlserver_password]




## Windows MS ODBC Problems?

If you are finding that your column data (national varchar, text, decimal, etc) is coming back as binary or the data is truncated with "\000\000" or "\000"? The solution – when setting up your ODBC Datasource (DSN) in odbcad32.exe make sure that:

  "Perform translation for character data" is OFF.
  "Use regional settings when outputting currency, numbers, dates and times" is OFF.

Thanks to @adamdennis for this.


## Ruby 1.9.1 on Rails 2.3.5 on Windows XP  [March 2010]

Before installing activerecord-sqlserver-adapter you have to install the "ruby-odbc gem":http://www.ch-werner.de/rubyodbc/
But beware ! It needs a C - compiler for installation.
Either you have a ten year old Microsoft MSVC++ 6.0 Compiler
or better you may install the "Ruby Development Kit":http://wiki.github.com/oneclick/rubyinstaller/development-kit first.

So step by step:

# "Install devkit":http://wiki.github.com/oneclick/rubyinstaller/development-kit
# gem install ruby-odbc
# gem install activerecord-sqlserver-adapter
# ??Maybe install??
    "Microsoft SQL Server 2005 Native Client":http://www.microsoft.com/downloads/details.aspx?FamilyID=536fd7d5-013f-49bc-9fc7-77dede4bb075&displaylang=en
        "Microsoft SQL Server 2008 Native Client":http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=b33d2c78-1059-4ce2-b80d-2343c099bcb4
# "Create a ODBC Data Source":http://msdn.microsoft.com/en-us/library/ms714024(VS.85).aspx
# ??Modify database.yml??
     development:
        adapter: sqlserver
       database: MyDatabase
       dsn: dsn_MyDatabase
       mode: odbc
       username: TestUser
       password: xxxxx
      encoding: utf8
# ??Create an activemodel??
    class Customer < ActiveRecord::Base
       set_table_name "dbo.Customer"
       set_primary_key "CustomerID"
    end
#  ??Create an activecontroller??
    class CustomerController < ApplicationController
       def index
           @customers = Customer.find(:all, :conditions => ["CustName LIKE 'Klaus%'"])
           respond_to do |format|
                format.html
           end
      end
   end
# ??StartRails:?? ruby script\server

and voilá : I get the error message : "failed to allocate memory"
ok, stay tuned I will do my best to find the failure cause

Update: the problem comes from a ntext column in my table ...
