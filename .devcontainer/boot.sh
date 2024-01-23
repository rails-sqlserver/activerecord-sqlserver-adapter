sudo chown -R vscode:vscode /usr/local/bundle

# Wait for 10 seconds to make sure SQL Server came up.
sleep 10

# Setup test databases and users.
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

# Mark directory as safe in Git so that commands run without warnings.
git config --global --add safe.directory /workspaces/activerecord-sqlserver-adapter
