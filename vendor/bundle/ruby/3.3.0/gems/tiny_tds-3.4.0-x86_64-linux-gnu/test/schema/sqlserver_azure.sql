
/*

  * Binary Data - Our test binary data is a 1 pixel gif. The basic (raw) data is below. Quoting this data
    would involve this (encode) method and be (encoded) with the 0x prefix for raw SQL. In other clients the
    (raw_db) value without the 0x prefix would need to be (packed) again yield the original (raw) value.

    (raw)     - "GIF89a\001\000\001\000\221\000\000\377\377\377\377\377\377\376\001\002\000\000\000!\371\004\004\024\000\377\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
    (encode)  - "0x#{raw.unpack("H*")[0]}"
    (encoded) - "0x47494638396101000100910000fffffffffffffe010200000021f904041400ff002c00000000010001000002024401003b"
    (raw_db)  - "47494638396101000100910000fffffffffffffe010200000021f904041400ff002c00000000010001000002024401003b"
    (packed)  - [raw_db].pack('H*')

*/

CREATE TABLE [dbo].[datatypes] (
  [id] [int] NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[bigint] [bigint] NULL,
	[binary_50] [binary](50) NULL,
	[bit] [bit] NULL,
	[char_10] [char](10) NULL,
	[date] [date] NULL,
	[datetime] [datetime] NULL,
	[datetime2_7] [datetime2](7) NULL,
	[datetime2_2] [datetime2](2) NULL,
	[datetimeoffset_2] [datetimeoffset](2) NULL,
	[datetimeoffset_7] [datetimeoffset](7) NULL,
	[decimal_9_2] [decimal](9, 2) NULL,
	[decimal_16_4] [decimal](16, 4) NULL,
	[float] [float] NULL,
	[geography] [geography] NULL,
	[geometry] [geometry] NULL,
	[hierarchyid] [hierarchyid] NULL,
	[image] [image] NULL,
	[int] [int] NULL,
	[money] [money] NULL,
	[nchar_10] [nchar](10) NULL,
	[ntext] [ntext] NULL,
	[numeric_18_0] [numeric](18, 0) NULL,
	[numeric_36_2] [numeric](36, 2) NULL,
	[nvarchar_50] [nvarchar](50) NULL,
	[nvarchar_max] [nvarchar](max) NULL,
	[real] [real] NULL,
	[smalldatetime] [smalldatetime] NULL,
	[smallint] [smallint] NULL,
	[smallmoney] [smallmoney] NULL,
	[text] [text] NULL,
	[time_2] [time](2) NULL,
	[time_7] [time](7) NULL,
	[timestamp] [timestamp] NULL,
	[tinyint] [tinyint] NULL,
	[uniqueidentifier] [uniqueidentifier] NULL,
	[varbinary_50] [varbinary](50) NULL,
	[varbinary_max] [varbinary](max) NULL,
	[varchar_50] [varchar](50) NULL,
	[varchar_max] [varchar](max) NULL,
	[xml] [xml] NULL
)

SET IDENTITY_INSERT [datatypes] ON

INSERT INTO [datatypes] ([id], [bigint])            VALUES ( 11, -9223372036854775807 )
INSERT INTO [datatypes] ([id], [bigint])            VALUES ( 12, 9223372036854775806 )
INSERT INTO [datatypes] ([id], [binary_50])         VALUES ( 21, 0x47494638396101000100910000fffffffffffffe010200000021f904041400ff002c00000000010001000002024401003b )
INSERT INTO [datatypes] ([id], [bit])               VALUES ( 31, 1 )
INSERT INTO [datatypes] ([id], [bit])               VALUES ( 32, 0 )
INSERT INTO [datatypes] ([id], [char_10])           VALUES ( 41, '1234567890' )
INSERT INTO [datatypes] ([id], [char_10])           VALUES ( 42, '12345678' )
INSERT INTO [datatypes] ([id], [date])              VALUES ( 51, '0001-01-01' )
INSERT INTO [datatypes] ([id], [date])              VALUES ( 52, '9999-12-31' )
INSERT INTO [datatypes] ([id], [datetime])          VALUES ( 61, '1753-01-01T00:00:00.000' )
INSERT INTO [datatypes] ([id], [datetime])          VALUES ( 62, '9999-12-31T23:59:59.997' )
INSERT INTO [datatypes] ([id], [datetime])          VALUES ( 63, '2010-01-01T12:34:56.123' )
INSERT INTO [datatypes] ([id], [datetime2_7])       VALUES ( 71, '0001-01-01 00:00:00.0000000' )
INSERT INTO [datatypes] ([id], [datetime2_7])       VALUES ( 72, '1984-01-24 04:20:00.0000000' )
INSERT INTO [datatypes] ([id], [datetime2_7])       VALUES ( 73, '9999-12-31 23:59:59.9999999' )
INSERT INTO [datatypes] ([id], [datetime2_2])       VALUES ( 74, '9999-12-31 23:59:59.123456789' )
INSERT INTO [datatypes] ([id], [datetimeoffset_2])  VALUES ( 81, '1984-01-24T04:20:00.1234567-08:00' ) -- 1984-01-24 04:20:00.00 -08:00
INSERT INTO [datatypes] ([id], [datetimeoffset_2])  VALUES ( 82, '1984-01-24T04:20:00.0000000Z' )      -- 1984-01-24 04:20:00.00 +00:00
INSERT INTO [datatypes] ([id], [datetimeoffset_2])  VALUES ( 83, '9999-12-31T23:59:59.9999999Z' )      -- 9999-12-31 23:59:59.99 +00:00
INSERT INTO [datatypes] ([id], [datetimeoffset_7])  VALUES ( 84, '1984-01-24T04:20:59.1234567-08:00' ) -- 1984-01-24 04:20:59.1234567 -08:00
INSERT INTO [datatypes] ([id], [datetimeoffset_7])  VALUES ( 85, '1984-01-24T04:20:00.0000000Z' )      -- 1984-01-24 04:20:00.0000000 +00:00
INSERT INTO [datatypes] ([id], [datetimeoffset_7])  VALUES ( 86, '9999-12-31T23:59:59.9999999Z' )      -- 9999-12-31 23:59:59.9999999 +00:00
INSERT INTO [datatypes] ([id], [decimal_9_2])       VALUES ( 91, 12345.01 )
INSERT INTO [datatypes] ([id], [decimal_9_2])       VALUES ( 92, 1234567.89 )
INSERT INTO [datatypes] ([id], [decimal_16_4])      VALUES ( 93, 0.0 )
INSERT INTO [datatypes] ([id], [decimal_16_4])      VALUES ( 94, 123456789012.3456 )
INSERT INTO [datatypes] ([id], [float])             VALUES ( 101, 123.00000001 )
INSERT INTO [datatypes] ([id], [float])             VALUES ( 102, 0.0 )
INSERT INTO [datatypes] ([id], [float])             VALUES ( 103, 123.45 )
INSERT INTO [datatypes] ([id], [geography])         VALUES ( 111, geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656)', 4326) ) -- 0xE610000001148716D9CEF7D34740D7A3703D0A975EC08716D9CEF7D34740CBA145B6F3955EC0
INSERT INTO [datatypes] ([id], [geometry])          VALUES ( 121, geometry::STGeomFromText('LINESTRING (100 100, 20 180, 180 180)', 0) ) -- 0x0000000001040300000000000000000059400000000000005940000000000000344000000000008066400000000000806640000000000080664001000000010000000001000000FFFFFFFF0000000002
INSERT INTO [datatypes] ([id], [hierarchyid])       VALUES ( 131, CAST('/1/' AS hierarchyid) ) -- 0x58
INSERT INTO [datatypes] ([id], [hierarchyid])       VALUES ( 132, CAST('/2/' AS hierarchyid) ) -- 0x68
INSERT INTO [datatypes] ([id], [image])             VALUES ( 141, 0x47494638396101000100910000fffffffffffffe010200000021f904041400ff002c00000000010001000002024401003b )
INSERT INTO [datatypes] ([id], [int])               VALUES ( 151, -2147483647 )
INSERT INTO [datatypes] ([id], [int])               VALUES ( 152, 2147483646 )
INSERT INTO [datatypes] ([id], [money])             VALUES ( 161, 4.20 )
INSERT INTO [datatypes] ([id], [money])             VALUES ( 162, -922337203685477.5807 )
INSERT INTO [datatypes] ([id], [money])             VALUES ( 163, 922337203685477.5806 )
INSERT INTO [datatypes] ([id], [nchar_10])          VALUES ( 171, N'1234567890' )
INSERT INTO [datatypes] ([id], [nchar_10])          VALUES ( 172, N'123456åå' )
INSERT INTO [datatypes] ([id], [nchar_10])          VALUES ( 173, N'abc123' )
INSERT INTO [datatypes] ([id], [ntext])             VALUES ( 181, N'test ntext' )
INSERT INTO [datatypes] ([id], [ntext])             VALUES ( 182, N'test ntext åå' )
INSERT INTO [datatypes] ([id], [numeric_18_0])      VALUES ( 191, 191 )
INSERT INTO [datatypes] ([id], [numeric_18_0])      VALUES ( 192, 123456789012345678 )
INSERT INTO [datatypes] ([id], [numeric_36_2])      VALUES ( 193, 12345678901234567890.01 )
INSERT INTO [datatypes] ([id], [numeric_36_2])      VALUES ( 194, 123.46 )
INSERT INTO [datatypes] ([id], [nvarchar_50])       VALUES ( 201, N'test nvarchar_50' )
INSERT INTO [datatypes] ([id], [nvarchar_50])       VALUES ( 202, N'test nvarchar_50 åå' )
INSERT INTO [datatypes] ([id], [nvarchar_max])      VALUES ( 211, N'test nvarchar_max' )
INSERT INTO [datatypes] ([id], [nvarchar_max])      VALUES ( 212, N'test nvarchar_max åå' )
INSERT INTO [datatypes] ([id], [real])              VALUES ( 221, 123.45 )
INSERT INTO [datatypes] ([id], [real])              VALUES ( 222, 0.0 )
INSERT INTO [datatypes] ([id], [real])              VALUES ( 223, 0.00001 )
INSERT INTO [datatypes] ([id], [smalldatetime])     VALUES ( 231, '1901-01-01T15:45:00.000Z' ) -- 1901-01-01 15:45:00
INSERT INTO [datatypes] ([id], [smalldatetime])     VALUES ( 232, '2078-06-05T04:20:00.000Z' ) -- 2078-06-05 04:20:00
INSERT INTO [datatypes] ([id], [smallint])          VALUES ( 241, -32767 )
INSERT INTO [datatypes] ([id], [smallint])          VALUES ( 242, 32766 )
INSERT INTO [datatypes] ([id], [smallmoney])        VALUES ( 251, 4.20 )
INSERT INTO [datatypes] ([id], [smallmoney])        VALUES ( 252, -214748.3647 )
INSERT INTO [datatypes] ([id], [smallmoney])        VALUES ( 253, 214748.3646 )
INSERT INTO [datatypes] ([id], [text])              VALUES ( 271, 'test text' )
INSERT INTO [datatypes] ([id], [time_2])            VALUES ( 281, '15:45:00.709714966' ) -- 15:45:00.71
INSERT INTO [datatypes] ([id], [time_2])            VALUES ( 282, '04:20:00.288321545' ) -- 04:20:00.29
INSERT INTO [datatypes] ([id], [time_7])            VALUES ( 283, '15:45:00.709714966' ) -- 15:45:00.709714900
INSERT INTO [datatypes] ([id], [time_7])            VALUES ( 284, '04:20:00.288321545' ) -- 04:20:00.288321500
INSERT INTO [datatypes] ([id], [tinyint])           VALUES ( 301, 0 )
INSERT INTO [datatypes] ([id], [tinyint])           VALUES ( 302, 255 )
INSERT INTO [datatypes] ([id], [uniqueidentifier])  VALUES ( 311, NEWID() )
INSERT INTO [datatypes] ([id], [varbinary_50])      VALUES ( 321, 0x47494638396101000100910000fffffffffffffe010200000021f904041400ff002c00000000010001000002024401003b )
INSERT INTO [datatypes] ([id], [varbinary_max])     VALUES ( 331, 0x47494638396101000100910000fffffffffffffe010200000021f904041400ff002c00000000010001000002024401003b )
INSERT INTO [datatypes] ([id], [varchar_50])        VALUES ( 341, 'test varchar_50' )
INSERT INTO [datatypes] ([id], [varchar_max])       VALUES ( 351, 'test varchar_max' )
INSERT INTO [datatypes] ([id], [xml])               VALUES ( 361, '<foo><bar>batz</bar></foo>' )

SET IDENTITY_INSERT [datatypes] OFF


