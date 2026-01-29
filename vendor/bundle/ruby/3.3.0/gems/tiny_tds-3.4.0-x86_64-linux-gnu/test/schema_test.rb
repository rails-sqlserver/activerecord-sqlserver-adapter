require "test_helper"

class SchemaTest < TinyTds::TestCase
  describe "Casting SQL Server schema" do
    before do
      @@current_schema_loaded ||= load_current_schema
      @client = new_connection
      @gif1px = File.read("test/schema/1px.gif", mode: "rb:BINARY")
    end

    it "casts bigint" do
      assert_equal(-9223372036854775807, find_value(11, :bigint))
      assert_equal 9223372036854775806, find_value(12, :bigint)
    end

    it "casts binary" do
      value = find_value(21, :binary_50)
      assert_equal @gif1px + "\000", value
      assert_binary_encoding(value)
    end

    it "casts bit" do
      assert_equal true, find_value(31, :bit)
      assert_equal false, find_value(32, :bit)
      assert_nil find_value(21, :bit)
    end

    it "casts char" do
      partial_char = "12345678  "
      assert_equal "1234567890", find_value(41, :char_10)
      assert_equal partial_char, find_value(42, :char_10)
      assert_utf8_encoding find_value(42, :char_10)
    end

    it "casts datetime" do
      # 1753-01-01T00:00:00.000
      v = find_value 61, :datetime
      assert_instance_of Time, v, "not in range of Time class"
      assert_equal 1753, v.year
      assert_equal 0o1, v.month
      assert_equal 0o1, v.day
      assert_equal 0, v.hour
      assert_equal 0, v.min
      assert_equal 0, v.sec
      assert_equal 0, v.usec
      # 9999-12-31T23:59:59.997
      v = find_value 62, :datetime
      assert_instance_of Time, v, "not in range of Time class"
      assert_equal 9999, v.year
      assert_equal 12, v.month
      assert_equal 31, v.day
      assert_equal 23, v.hour
      assert_equal 59, v.min
      assert_equal 59, v.sec
      assert_equal 997000, v.usec
      assert_equal utc_offset, find_value(62, :datetime, timezone: :local).utc_offset
      assert_equal 0, find_value(62, :datetime, timezone: :utc).utc_offset
      # 2010-01-01T12:34:56.123
      v = find_value 63, :datetime
      assert_instance_of Time, v, "in range of Time class"
      assert_equal 2010, v.year
      assert_equal 0o1, v.month
      assert_equal 0o1, v.day
      assert_equal 12, v.hour
      assert_equal 34, v.min
      assert_equal 56, v.sec
      assert_equal 123000, v.usec
      assert_equal utc_offset, find_value(63, :datetime, timezone: :local).utc_offset
      assert_equal 0, find_value(63, :datetime, timezone: :utc).utc_offset
    end

    it "casts decimal" do
      assert_instance_of BigDecimal, find_value(91, :decimal_9_2)
      assert_equal BigDecimal("12345.01"), find_value(91, :decimal_9_2)
      assert_equal BigDecimal("1234567.89"), find_value(92, :decimal_9_2)
      assert_equal BigDecimal("0.0"), find_value(93, :decimal_16_4)
      assert_equal BigDecimal("123456789012.3456"), find_value(94, :decimal_16_4)
    end

    it "casts float" do
      assert_equal 123.00000001, find_value(101, :float)
      assert_equal 0.0, find_value(102, :float)
      assert_equal find_value(102, :float).object_id, find_value(102, :float).object_id, "use global zero float"
      assert_equal 123.45, find_value(103, :float)
    end

    it "casts image" do
      value = find_value(141, :image)
      assert_equal @gif1px, value
      assert_binary_encoding(value)
    end

    it "casts int" do
      assert_equal(-2147483647, find_value(151, :int))
      assert_equal 2147483646, find_value(152, :int)
    end

    it "casts money" do
      assert_instance_of BigDecimal, find_value(161, :money)
      assert_equal BigDecimal("4.20"), find_value(161, :money)
      assert_equal BigDecimal("922337203685477.5806"), find_value(163, :money)
      assert_equal BigDecimal("-922337203685477.5807"), find_value(162, :money)
    end

    it "casts nchar" do
      assert_equal "1234567890", find_value(171, :nchar_10)
      assert_equal "123456åå  ", find_value(172, :nchar_10)
      assert_equal "abc123    ", find_value(173, :nchar_10)
    end

    it "casts ntext" do
      assert_equal "test ntext", find_value(181, :ntext)
      assert_equal "test ntext åå", find_value(182, :ntext)
      assert_utf8_encoding find_value(182, :ntext)
      # If this test fails, try setting the "text size" in your freetds.conf. See: http://www.freetds.org/faq.html#textdata
      large_value = "x" * 5000
      large_value_id = @client.execute("INSERT INTO [datatypes] ([ntext]) VALUES (N'#{large_value}')").insert
      assert_equal large_value, find_value(large_value_id, :ntext)
    end

    it "casts numeric" do
      assert_instance_of BigDecimal, find_value(191, :numeric_18_0)
      assert_equal BigDecimal("191"), find_value(191, :numeric_18_0)
      assert_equal BigDecimal("123456789012345678"), find_value(192, :numeric_18_0)
      assert_equal BigDecimal("12345678901234567890.01"), find_value(193, :numeric_36_2)
      assert_equal BigDecimal("123.46"), find_value(194, :numeric_36_2)
    end

    it "casts nvarchar" do
      assert_equal "test nvarchar_50", find_value(201, :nvarchar_50)
      assert_equal "test nvarchar_50 åå", find_value(202, :nvarchar_50)
      assert_utf8_encoding find_value(202, :nvarchar_50)
    end

    it "casts real" do
      assert_in_delta 123.45, find_value(221, :real), 0.01
      assert_equal 0.0, find_value(222, :real)
      assert_equal find_value(222, :real).object_id, find_value(222, :real).object_id, "use global zero float"
      assert_in_delta 0.00001, find_value(223, :real), 0.000001
    end

    it "casts smalldatetime" do
      # 1901-01-01 15:45:00
      v = find_value 231, :smalldatetime
      assert_instance_of Time, v
      assert_equal 1901, v.year
      assert_equal 0o1, v.month
      assert_equal 0o1, v.day
      assert_equal 15, v.hour
      assert_equal 45, v.min
      assert_equal 0o0, v.sec
      assert_equal Time.local(1901).utc_offset, find_value(231, :smalldatetime, timezone: :local).utc_offset
      assert_equal 0, find_value(231, :smalldatetime, timezone: :utc).utc_offset
      # 2078-06-05 04:20:00
      v = find_value 232, :smalldatetime
      assert_instance_of Time, v
      assert_equal 2078, v.year
      assert_equal 0o6, v.month
      assert_equal 0o5, v.day
      assert_equal 0o4, v.hour
      assert_equal 20, v.min
      assert_equal 0o0, v.sec
      assert_equal Time.local(2078, 6).utc_offset, find_value(232, :smalldatetime, timezone: :local).utc_offset
      assert_equal 0, find_value(232, :smalldatetime, timezone: :utc).utc_offset
    end

    it "casts smallint" do
      assert_equal(-32767, find_value(241, :smallint))
      assert_equal 32766, find_value(242, :smallint)
    end

    it "casts smallmoney" do
      assert_instance_of BigDecimal, find_value(251, :smallmoney)
      assert_equal BigDecimal("4.20"), find_value(251, :smallmoney)
      assert_equal BigDecimal("-214748.3647"), find_value(252, :smallmoney)
      assert_equal BigDecimal("214748.3646"), find_value(253, :smallmoney)
    end

    it "casts text" do
      assert_equal "test text", find_value(271, :text)
      assert_utf8_encoding find_value(271, :text)
    end

    it "casts tinyint" do
      assert_equal 0, find_value(301, :tinyint)
      assert_equal 255, find_value(302, :tinyint)
    end

    it "casts uniqueidentifier" do
      assert_match %r|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}|, find_value(311, :uniqueidentifier)
      assert_utf8_encoding find_value(311, :uniqueidentifier)
    end

    it "casts varbinary" do
      value = find_value(321, :varbinary_50)
      assert_equal @gif1px, value
      assert_binary_encoding(value)
    end

    it "casts varchar" do
      assert_equal "test varchar_50", find_value(341, :varchar_50)
      assert_utf8_encoding find_value(341, :varchar_50)
    end

    it "casts nvarchar(max)" do
      assert_equal "test nvarchar_max", find_value(211, :nvarchar_max)
      assert_equal "test nvarchar_max åå", find_value(212, :nvarchar_max)
      assert_utf8_encoding find_value(212, :nvarchar_max)
    end

    it "casts varbinary(max)" do
      value = find_value(331, :varbinary_max)
      assert_equal @gif1px, value
      assert_binary_encoding(value)
    end

    it "casts varchar(max)" do
      value = find_value(351, :varchar_max)
      assert_equal "test varchar_max", value
      assert_utf8_encoding(value)
    end

    it "casts xml" do
      value = find_value(361, :xml)
      assert_equal "<foo><bar>batz</bar></foo>", value
      assert_utf8_encoding(value)
    end

    it "casts date" do
      # 0001-01-01
      v = find_value 51, :date
      if @client.tds_73?
        assert_instance_of Date, v
        assert_equal 1, v.year, "Year"
        assert_equal 1, v.month, "Month"
        assert_equal 1, v.day, "Day"
      else
        assert_equal "0001-01-01", v
      end
      # 9999-12-31
      v = find_value 52, :date
      if @client.tds_73?
        assert_instance_of Date, v
        assert_equal 9999, v.year, "Year"
        assert_equal 12, v.month, "Month"
        assert_equal 31, v.day, "Day"
      else
        assert_equal "9999-12-31", v
      end
    end

    it "casts time" do
      # 15:45:00.709714966
      v = find_value 281, :time_2
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 1900, v.year, "Year"
        assert_equal 1, v.month, "Month"
        assert_equal 1, v.day, "Day"
        assert_equal 15, v.hour, "Hour"
        assert_equal 45, v.min, "Minute"
        assert_equal 0, v.sec, "Second"
        assert_equal 710000, v.usec, "Microseconds"
        assert_equal 710000000, v.nsec, "Nanoseconds"
      else
        assert_equal "15:45:00.71", v
      end
      # 04:20:00.288321545
      v = find_value 282, :time_2
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 1900, v.year, "Year"
        assert_equal 1, v.month, "Month"
        assert_equal 1, v.day, "Day"
        assert_equal 4, v.hour, "Hour"
        assert_equal 20, v.min, "Minute"
        assert_equal 0, v.sec, "Second"
        assert_equal 290000, v.usec, "Microseconds"
        assert_equal 290000000, v.nsec, "Nanoseconds"
      else
        assert_equal "04:20:00.29", v
      end
      # 15:45:00.709714966
      v = find_value 283, :time_7
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 1900, v.year, "Year"
        assert_equal 1, v.month, "Month"
        assert_equal 1, v.day, "Day"
        assert_equal 15, v.hour, "Hour"
        assert_equal 45, v.min, "Minute"
        assert_equal 0, v.sec, "Second"
        assert_equal 709715, v.usec, "Microseconds"
        assert_equal 709715000, v.nsec, "Nanoseconds"
      else
        assert_equal "15:45:00.7097150", v
      end
      # 04:20:00.288321545
      v = find_value 284, :time_7
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 1900, v.year, "Year"
        assert_equal 1, v.month, "Month"
        assert_equal 1, v.day, "Day"
        assert_equal 4, v.hour, "Hour"
        assert_equal 20, v.min, "Minute"
        assert_equal 0, v.sec, "Second"
        assert_equal 288321, v.usec, "Microseconds"
        assert_equal 288321500, v.nsec, "Nanoseconds"
      else
        assert_equal "04:20:00.2883215", v
      end
    end

    it "casts datetime2" do
      # 0001-01-01 00:00:00.0000000
      v = find_value 71, :datetime2_7
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 1, v.year, "Year"
        assert_equal 1, v.month, "Month"
        assert_equal 1, v.day, "Day"
        assert_equal 0, v.hour, "Hour"
        assert_equal 0, v.min, "Minute"
        assert_equal 0, v.sec, "Second"
        assert_equal 0, v.usec, "Microseconds"
        assert_equal 0, v.nsec, "Nanoseconds"
      else
        assert_equal "0001-01-01 00:00:00.0000000", v
      end
      # 1984-01-24 04:20:00.0000000
      v = find_value 72, :datetime2_7
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 1984, v.year, "Year"
        assert_equal 1, v.month, "Month"
        assert_equal 24, v.day, "Day"
        assert_equal 4, v.hour, "Hour"
        assert_equal 20, v.min, "Minute"
        assert_equal 0, v.sec, "Second"
        assert_equal 0, v.usec, "Microseconds"
        assert_equal 0, v.nsec, "Nanoseconds"
      else
        assert_equal "1984-01-24 04:20:00.0000000", v
      end
      # 9999-12-31 23:59:59.9999999
      v = find_value 73, :datetime2_7
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 9999, v.year, "Year"
        assert_equal 12, v.month, "Month"
        assert_equal 31, v.day, "Day"
        assert_equal 23, v.hour, "Hour"
        assert_equal 59, v.min, "Minute"
        assert_equal 59, v.sec, "Second"
        assert_equal 999999, v.usec, "Microseconds"
        assert_equal 999999900, v.nsec, "Nanoseconds"
      else
        assert_equal "9999-12-31 23:59:59.9999999", v
      end
      # 9999-12-31 23:59:59.123456789
      v = find_value 74, :datetime2_2
      if @client.tds_73?
        assert_instance_of Time, v
        assert_equal 9999, v.year, "Year"
        assert_equal 12, v.month, "Month"
        assert_equal 31, v.day, "Day"
        assert_equal 23, v.hour, "Hour"
        assert_equal 59, v.min, "Minute"
        assert_equal 59, v.sec, "Second"
        assert_equal 120000, v.usec, "Microseconds"
        assert_equal 120000000, v.nsec, "Nanoseconds"
      else
        assert_equal "9999-12-31 23:59:59.12", v
      end
    end

    it "casts datetimeoffset" do
      # 1984-01-24T04:20:00.1234567-08:00
      v = find_value 84, :datetimeoffset_7
      if @client.tds_73?
        assertions = lambda {
          assert_instance_of Time, v
          assert_equal 1984, v.year, "Year"
          assert_equal 1, v.month, "Month"
          assert_equal 24, v.day, "Day"
          assert_equal 4, v.hour, "Hour"
          assert_equal 20, v.min, "Minute"
          assert_equal 59, v.sec, "Second"
          assert_equal 123456, v.usec, "Microseconds"
          assert_equal 123456700, v.nsec, "Nanoseconds"
          assert_equal(-28800, v.utc_offset, "Offset")
        }
        assertions.call
        v = find_value 84, :datetimeoffset_7, timezone: :local
        assertions.call # Ignores timezone query option.
      else
        assert_equal "1984-01-24 04:20:59.1234567 -08:00", v
      end
    end

    # it 'casts geography' do
    #   value = find_value 111, :geography
    #   assert_equal '', value
    # end
    #
    # it 'casts geometry' do
    #   value = find_value 121, :geometry
    #   assert_equal '', value
    # end
    #
    # it 'casts hierarchyid' do
    #   value = find_value 131, :hierarchyid
    #   assert_equal '', value
    # end
  end
end
