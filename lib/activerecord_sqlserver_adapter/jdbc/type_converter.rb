module ActiveRecordSqlServerAdapter
  module Jdbc
    class TypeConverter
      OPTS = {}.freeze

      %w'Boolean Float Double Int Long Short'.each do |meth|
        class_eval("def #{meth}(r, i, opts=OPTS) v = r.get#{meth}(i); v unless r.wasNull end", __FILE__, __LINE__)
      end
      %w'Object Array String Bytes'.each do |meth|
        class_eval("def #{meth}(r, i, opts=OPTS) r.get#{meth}(i) end", __FILE__, __LINE__)
      end
      def RubyTime(r, i, opts=OPTS)
        if v = r.getString(i)
          timezone = opts[:database_timezone] == :utc ? 'UTC' : ''
          Time.parse("2000-01-01 #{v}#{timezone}")
        end
      end
      def RubyDate(r, i, opts=OPTS)
        if v = r.getDate(i)
          Date.civil(v.getYear + 1900, v.getMonth + 1, v.getDate)
        end
      end
      def RubyTimestamp(r, i, opts=OPTS)
        if v = r.getTimestamp(i)
          timezone = opts[:database_timezone] == :local ? :local : :utc
          Time.send(timezone, v.getYear + 1900, v.getMonth + 1, v.getDate, v.getHours, v.getMinutes, v.getSeconds, v.getNanos / 1000.0)
        end
      end
      def RubyDateTimeOffset(r, i, opts=OPTS)
        if v = r.getString(i)
          timezone = opts[:database_timezone] == :local ? :local : :utc
          Time.parse(v.to_s).send(timezone)
        end
      end
      def RubyBigDecimal(r, i, opts=OPTS)
        if v = r.getBigDecimal(i)
          BigDecimal.new(v.to_string)
        end
      end
      def RubyBlob(r, i, opts=OPTS)
        if v = r.getBytes(i)
          String.from_java_bytes(v)
        end
      end
      def RubyClob(r, i, opts=OPTS)
        if v = r.getClob(i)
          v.getSubString(1, v.length)
        end
      end

      INSTANCE = new
      o = INSTANCE
      MAP = Hash.new(o.method(:Object))
      types = Java::JavaSQL::Types

      {
          :ARRAY => :Array,
          :BOOLEAN => :Boolean,
          :CHAR => :String,
          :DOUBLE => :Double,
          :FLOAT => :Double,
          :INTEGER => :Int,
          :LONGNVARCHAR => :String,
          :LONGVARCHAR => :String,
          :NCHAR => :String,
          :REAL => :Float,
          :SMALLINT => :Short,
          :TINYINT => :Short,
          :VARCHAR => :String,
      }.each do |type, meth|
        MAP[types.const_get(type)] = o.method(meth)
      end

      {
          :BINARY => :Blob,
          :BLOB => :Blob,
          :CLOB => :Clob,
          :DATE => :Date,
          :DECIMAL => :BigDecimal,
          :LONGVARBINARY => :Blob,
          :NCLOB => :Clob,
          :NUMERIC => :BigDecimal,
          :TIME => :Time,
          :TIMESTAMP => :Timestamp,
          :VARBINARY => :Blob,
      }.each do |type, meth|
        MAP[types.const_get(type)] = o.method(:"Ruby#{meth}")
      end

      MAP[::Java::MicrosoftSql::Types::DATETIMEOFFSET] = o.method(:RubyDateTimeOffset)

      MAP.freeze
      INSTANCE.freeze
    end
  end
end
