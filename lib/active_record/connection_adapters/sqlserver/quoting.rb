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
          SQLServer::Utils.extract_identifiers(name).quoted
        end

        def quote_default_value(value, column)
          if column.type == :uuid && value =~ /\(\)/
            value
          else
            quote(value, column)
          end
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

        def quoted_date(value)
          SQLServer::Utils.with_sqlserver_db_date_formats do
            if value.acts_like?(:time) && value.respond_to?(:usec)
              precision = (BigDecimal(value.usec.to_s) / 1_000_000).round(3).to_s.split('.').last
              "#{super}.#{precision}"
            elsif value.acts_like?(:date)
              value.to_s(:_sqlserver_dateformat)
            else
              super
            end
          end
        end


        private

        def _quote(value)
          case value
          when Type::Binary::Data
            "0x#{value.hex}"
          when SQLServer::Type::Quoter
            value.quote_ss_value
          when String, ActiveSupport::Multibyte::Chars
            if value.is_utf8?
              "#{QUOTED_STRING_PREFIX}#{super}"
            else
              super
            end
          else
            super
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
