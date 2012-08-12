module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module Quoting
        
        QUOTED_TRUE, QUOTED_FALSE = '1', '0'
        QUOTED_STRING_PREFIX = 'N'
        
        def quote(value, column = nil)
          case value
          when String, ActiveSupport::Multibyte::Chars
            if column && column.type == :integer && value.blank?
              value.to_i.to_s
            elsif column && column.type == :binary
              column.class.string_to_binary(value)
            elsif value.is_utf8? || (column && column.type == :string)
              "#{quoted_string_prefix}'#{quote_string(value)}'"
            else
              super
            end
          when Date, Time
            if column && column.sql_type == 'datetime'
              "'#{quoted_datetime(value)}'"
            elsif column && (column.sql_type == 'datetimeoffset' || column.sql_type == 'time')
              "'#{quoted_full_iso8601(value)}'"
            else
              super
            end
          when nil
            column.respond_to?(:sql_type) && column.sql_type == 'timestamp' ? 'DEFAULT' : super
          else
            super
          end
        end
        
        def quoted_string_prefix
          QUOTED_STRING_PREFIX
        end
        
        def quote_string(string)
          string.to_s.gsub(/\'/, "''")
        end

        def quote_column_name(name)
          schema_cache.quote_name(name)
        end

        def quote_table_name(name)
          quote_column_name(name)
        end
        
        def substitute_at(column, index)
          if column.respond_to?(:sql_type) && column.sql_type == 'timestamp'
            nil
          else
            Arel.sql "@#{index}"
          end
        end

        def quoted_true
          QUOTED_TRUE
        end

        def quoted_false
          QUOTED_FALSE
        end

        def quoted_datetime(value)
          if value.acts_like?(:time)
            time_zone_qualified_value = quoted_value_acts_like_time_filter(value)
            if value.is_a?(Date)
              time_zone_qualified_value.to_time.xmlschema.to(18)
            else
              # CHANGED [Ruby 1.8] Not needed when 1.8 is dropped.
              if value.is_a?(ActiveSupport::TimeWithZone) && RUBY_VERSION < '1.9'
                time_zone_qualified_value = time_zone_qualified_value.to_time 
              end
              time_zone_qualified_value.iso8601(3).to(22)
            end
          else
            quoted_date(value)
          end
        end
        
        def quoted_full_iso8601(value)
          if value.acts_like?(:time)
            value.is_a?(Date) ? quoted_value_acts_like_time_filter(value).to_time.xmlschema.to(18) : quoted_value_acts_like_time_filter(value).iso8601(7).to(22)
          else
            quoted_date(value)
          end
        end

        def quoted_date(value)
          if value.acts_like?(:time) && value.respond_to?(:usec)
            "#{super}.#{sprintf("%03d",value.usec/1000)}"
          elsif value.acts_like?(:date)
            value.to_s(:_sqlserver_dateformat)
          else
            super
          end
        end
        
        protected
        
        def quoted_value_acts_like_time_filter(value)
          zone_conversion_method = ActiveRecord::Base.default_timezone == :utc ? :getutc : :getlocal
          value.respond_to?(zone_conversion_method) ? value.send(zone_conversion_method) : value
        end
        
      end
    end
  end
end
