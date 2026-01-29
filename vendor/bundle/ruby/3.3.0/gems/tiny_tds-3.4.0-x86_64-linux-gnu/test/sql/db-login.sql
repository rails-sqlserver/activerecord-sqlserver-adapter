:ON ERROR EXIT

PRINT 'RUNNING DB-LOGIN.SQL';

PRINT 'CREATING TINYTDS TEST LOGIN';
IF NOT EXISTS (select name from sys.server_principals where name like 'tinytds')
BEGIN
  CREATE LOGIN [tinytds] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [tinytdstest];
END
GO

IF EXISTS (select name from sys.server_principals where name like 'tinytds')
BEGIN
  PRINT 'TINY TDS TEST LOGIN SUCCESSFULY CREATED';
END
ELSE
BEGIN
  THROW 51000, 'TINY TDS TEST LOGIN CREATION FAILED', 1;
END
GO

USE [tinytdstest];
IF NOT EXISTS (select name from sys.database_principals where name LIKE 'tinytds')
BEGIN
  CREATE USER [tinytds] FOR LOGIN [tinytds];
  EXEC sp_addrolemember N'db_owner', N'tinytds';
END
GO

IF EXISTS (select name from sys.database_principals where name LIKE 'tinytds')
BEGIN
  PRINT 'TINY TDS TEST USER SUCCESSFULY CREATED';
END
ELSE
BEGIN
  THROW 51000, 'TINY TDS TEST USER CREATION FAILED', 1;
END
GO
