
IF EXISTS (
  SELECT TABLE_NAME
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_NAME = N'datatypes'
) DROP TABLE [datatypes]

CREATE TABLE [datatypes] (
  -- Exact Numerics
  [id] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
  [bigint] [bigint] NULL,
  [int] [int] NULL,
  [smallint] [smallint] NULL,
  [tinyint] [tinyint] NULL,
  [bit] [bit] NULL,
  [decimal_9_2] [decimal](9, 2) NULL,
  [decimal_16_4] [decimal](16, 4) NULL,
  [numeric_18_0] [numeric](18, 0) NULL,
  [numeric_36_2] [numeric](36, 2) NULL,
  [money] [money] NULL,
  [smallmoney] [smallmoney] NULL,
  -- Approximate Numerics
  [float] [float] NULL,
  [float_25] [float](25) NULL,
  [real] [real] NULL,
  -- Date and Time
  [date] [date] NULL,
  [datetime] [datetime] NULL,
  [smalldatetime] [smalldatetime] NULL,
  [time_2] [time](2) NULL,
  [time_7] [time](7) NULL,
  -- Character Strings
  [char_10] [char](10) NULL,
  [varchar_50] [varchar](50) NULL,
  [varchar_max] [varchar](max) NULL,
  [text] [text] NULL,
  -- Unicode Character Strings
  [nchar_10] [nchar](10) NULL,
  [nvarchar_50] [nvarchar](50) NULL,
  [nvarchar_max] [nvarchar](max) NULL,
  [ntext] [ntext] NULL,
  -- Binary Strings
  [binary_49] [binary](49) NULL,
  [varbinary_49] [varbinary](49) NULL,
  [varbinary_max] [varbinary](max) NULL,
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


-- Date and Time (TODO)
-- --------------------
-- [datetime2_7] [datetime2](7) NULL,
-- [datetimeoffset_2] [datetimeoffset](2) NULL,
-- [datetimeoffset_7] [datetimeoffset](7) NULL,
--
-- INSERT INTO [datatypes] ([id], [datetime2_7])       VALUES ( 71, '0001-01-01T00:00:00.0000000Z' )
-- INSERT INTO [datatypes] ([id], [datetime2_7])       VALUES ( 72, '1984-01-24T04:20:00.0000000-08:00' )
-- INSERT INTO [datatypes] ([id], [datetime2_7])       VALUES ( 73, '9999-12-31T23:59:59.9999999Z' )
-- INSERT INTO [datatypes] ([id], [datetimeoffset_2])  VALUES ( 81, '1984-01-24T04:20:00.0000000-08:00' ) -- 1984-01-24 04:20:00.00 -08:00
-- INSERT INTO [datatypes] ([id], [datetimeoffset_2])  VALUES ( 82, '1984-01-24T04:20:00.0000000Z' )      -- 1984-01-24 04:20:00.00 +00:00
-- INSERT INTO [datatypes] ([id], [datetimeoffset_2])  VALUES ( 83, '9999-12-31T23:59:59.9999999Z' )      -- 9999-12-31 23:59:59.99 +00:00
-- INSERT INTO [datatypes] ([id], [datetimeoffset_7])  VALUES ( 84, '1984-01-24T04:20:00.0000000-08:00' ) -- 1984-01-24 04:20:00.0000000 -08:00
-- INSERT INTO [datatypes] ([id], [datetimeoffset_7])  VALUES ( 85, '1984-01-24T04:20:00.0000000Z' )      -- 1984-01-24 04:20:00.0000000 +00:00
-- INSERT INTO [datatypes] ([id], [datetimeoffset_7])  VALUES ( 86, '9999-12-31T23:59:59.9999999Z' )      -- 9999-12-31 23:59:59.9999999 +00:00
