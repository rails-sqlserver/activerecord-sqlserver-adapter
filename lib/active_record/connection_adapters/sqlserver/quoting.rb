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
          if value.acts_like?(:date)
            Type::Date.new.type_cast_for_database(value)
          else value.acts_like?(:time)
            Type::DateTime.new.type_cast_for_database(value)
          end
        end


        private

        def _quote(value)
          case value
          when Type::Binary::Data
            "0x#{value.hex}"
          when ActiveRecord::Type::SQLServer::Char::Data
            value.quoted
          when String, ActiveSupport::Multibyte::Chars
            "#{QUOTED_STRING_PREFIX}#{super}"
          else
            super
          end
        end

      end
    end
  end
end
