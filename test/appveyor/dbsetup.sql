CREATE DATABASE [activerecord_unittest];
CREATE DATABASE [activerecord_unittest2];
GO
CREATE LOGIN [rails] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [activerecord_unittest];
GO
EXEC sp_addrolemember N'sysadmin', N'rails';
GO
USE [activerecord_unittest];
CREATE USER [rails] FOR LOGIN [rails];
GO
EXEC sp_addrolemember N'db_owner', N'rails';
GO
