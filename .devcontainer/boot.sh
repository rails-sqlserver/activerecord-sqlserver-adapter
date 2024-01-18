#bundle install
#yarn install

sudo chown -R vscode:vscode /usr/local/bundle

#cd activerecord
#
## Create PostgreSQL databases
#bundle exec rake db:postgresql:rebuild
#
## Create MySQL databases
#MYSQL_CODESPACES=1 bundle exec rake db:mysql:rebuild


/opt/mssql-tools18/bin/sqlcmd -C -S sqlserver -U sa -P "MSSQLadmin!" <<SQL
CREATE DATABASE [activerecord_unittest];
CREATE DATABASE [activerecord_unittest2];
GO
CREATE LOGIN [rails] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [activerecord_unittest];
GO
USE [activerecord_unittest];
CREATE USER [rails] FOR LOGIN [rails];
GO
EXEC sp_addrolemember N'db_owner', N'rails';
EXEC master..sp_addsrvrolemember @loginame = N'rails', @rolename = N'sysadmin';
GO
SQL
