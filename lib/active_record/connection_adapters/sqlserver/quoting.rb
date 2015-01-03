module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Quoting

        QUOTED_TRUE  = '1'
        QUOTED_FALSE = '0'
        QUOTED_STRING_PREFIX = 'N'

        def quote_string(s)
          SQLServer::Utils.quote_string(s)
        end

        def quote_column_name(name)
          SQLServer::Utils.extract_identifiers(name).object_quoted
        end

        def quote_default_value(value, column)
          if column.type == :uuid && value =~ /\(\)/
            value
          else
            quote(value)
          end
        end

        def substitute_at(column, _unused = 0)
          return nil if column.respond_to?(:sql_type) && column.sql_type == 'timestamp'
          super
        end

        def quoted_true
          QUOTED_TRUE
        end

        def unquoted_true
          1
        end

        def quoted_false
          QUOTED_FALSE
        end

        def unquoted_false
          0
        end

        def quoted_datetime(value)
          if value.acts_like?(:time)
            time_zone_qualified_value = quoted_value_acts_like_time_filter(value)
            if value.is_a?(Date)
              time_zone_qualified_value.iso8601(3).to(18)
            else
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
            "#{super}.#{sprintf('%03d', value.usec / 1000)}"
          elsif value.acts_like?(:date)
            value.to_s(:_sqlserver_dateformat)
          else
            super
          end
        end


        private

        def _quote(value) # , column = nil
          case value
          when String, ActiveSupport::Multibyte::Chars
            if value.is_utf8?
              "#{QUOTED_STRING_PREFIX}#{super}"
            else
              super
            end
          else
            super(value)
          end
        end

        def quoted_value_acts_like_time_filter(value)
          zone_conversion_method = ActiveRecord::Base.default_timezone == :utc ? :getutc : :getlocal
          value.respond_to?(zone_conversion_method) ? value.send(zone_conversion_method) : value
        end

      end
    end
  end
end
