
IF EXISTS (
  SELECT TABLE_NAME
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_NAME = N'sst_datatypes'
) DROP TABLE [sst_datatypes]

CREATE TABLE [sst_datatypes] (
  -- Exact Numerics
  [id] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
  [bigint] [bigint] NULL DEFAULT 42,
  [int] [int] NULL DEFAULT 42,
  [smallint] [smallint] NULL DEFAULT 42,
  [tinyint] [tinyint] NULL DEFAULT 42,
  [bit] [bit] NULL DEFAULT 1,
  [decimal_9_2] [decimal](9, 2) NULL DEFAULT 12345.01,
  [decimal_16_4] [decimal](16, 4) NULL DEFAULT 1234567.89,
  [numeric_18_0] [numeric](18, 0) NULL DEFAULT 191,
  [numeric_36_2] [numeric](36, 2) NULL DEFAULT 12345678901234567890.01,
  [money] [money] NULL DEFAULT 4.20,
  [smallmoney] [smallmoney] NULL DEFAULT 4.20,
  -- Approximate Numerics
  [float] [float] NULL DEFAULT 123.00000001,
  [real] [real] NULL DEFAULT 123.45,
  -- Date and Time
  [date] [date] NULL DEFAULT '0001-01-01',
  [datetime] [datetime] NULL DEFAULT '1753-01-01T00:00:00.123',
  [datetime2_7] [datetime2](7) NULL DEFAULT '9999-12-31 23:59:59.9999999',
  [datetime2_3] [datetime2](3) NULL,
  [datetime2_1] [datetime2](1) NULL,
  [datetime2_0] [datetime2](0) NULL,
  [datetimeoffset_7] [datetimeoffset](7) NULL DEFAULT '1984-01-24 04:20:00.1234567 -08:00',
  [datetimeoffset_3] [datetimeoffset](3) NULL,
  [datetimeoffset_1] [datetimeoffset](1) NULL,
  [smalldatetime] [smalldatetime] NULL DEFAULT '1901-01-01T15:45:00.000Z',
  [time_7] [time](7) NULL DEFAULT '04:20:00.2883215',
  [time_2] [time](2) NULL,
  -- Character Strings
  [char_10] [char](10) NULL DEFAULT '1234567890',
  [varchar_50] [varchar](50) NULL DEFAULT 'test varchar_50',
  [varchar_max] [varchar](max) NULL DEFAULT 'test varchar_max',
  [text] [text] NULL DEFAULT 'test text',
  -- Unicode Character Strings
  [nchar_10] [nchar](10) NULL DEFAULT N'12345678åå',
  [nvarchar_50] [nvarchar](50) NULL DEFAULT N'test nvarchar_50 åå',
  [nvarchar_max] [nvarchar](max) NULL DEFAULT N'test nvarchar_max åå',
  [ntext] [ntext] NULL DEFAULT N'test ntext åå',
  -- Binary Strings
  [binary_49] [binary](49) NULL,
  [varbinary_49] [varbinary](49) NULL,
  [varbinary_max] [varbinary](max) NULL,
  -- Other Data Types
  [uniqueidentifier] [uniqueidentifier] NULL DEFAULT NEWID(),
  [timestamp] [timestamp] NULL,
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
