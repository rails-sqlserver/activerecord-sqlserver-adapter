# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Quoting
        QUOTED_TRUE  = "1".freeze
        QUOTED_FALSE = "0".freeze
        QUOTED_STRING_PREFIX = "N".freeze

        def fetch_type_metadata(sql_type, sqlserver_options = {})
          cast_type = lookup_cast_type(sql_type)
          SQLServer::SqlTypeMetadata.new(
            sql_type: sql_type,
            type: cast_type.type,
            limit: cast_type.limit,
            precision: cast_type.precision,
            scale: cast_type.scale,
            sqlserver_options: sqlserver_options
          )
        end

        def quote_string(s)
          SQLServer::Utils.quote_string(s)
        end

        def quote_string_single(s)
          SQLServer::Utils.quote_string_single(s)
        end

        def quote_string_single_national(s)
          SQLServer::Utils.quote_string_single_national(s)
        end

        def quote_column_name(name)
          SQLServer::Utils.extract_identifiers(name).quoted
        end

        def quote_default_expression(value, column)
          cast_type = lookup_cast_type(column.sql_type)
          if cast_type.type == :uuid && value =~ /\(\)/
            value
          else
            super
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
          if value.acts_like?(:time)
            Type::DateTime.new.serialize(value)
          elsif value.acts_like?(:date)
            Type::Date.new.serialize(value)
          else
            value
          end
        end

        def column_name_matcher
          COLUMN_NAME
        end

        def column_name_with_order_matcher
          COLUMN_NAME_WITH_ORDER
        end

        COLUMN_NAME = /
          \A
          (
            (?:
              # [table_name].[column_name] | function(one or no argument)
              ((?:\w+\.|\[\w+\]\.)?(?:\w+|\[\w+\])) | \w+\((?:|\g<2>)\)
            )
            (?:\s+AS\s+(?:\w+|\[\w+\]))?
          )
          (?:\s*,\s*\g<1>)*
          \z
        /ix

        COLUMN_NAME_WITH_ORDER = /
          \A
          (
            (?:
              # [table_name].[column_name] | function(one or no argument)
              ((?:\w+\.|\[\w+\]\.)?(?:\w+|\[\w+\])) | \w+\((?:|\g<2>)\)
            )
            (?:\s+ASC|\s+DESC)?
            (?:\s+NULLS\s+(?:FIRST|LAST))?
          )
          (?:\s*,\s*\g<1>)*
          \z
        /ix

        private_constant :COLUMN_NAME, :COLUMN_NAME_WITH_ORDER

        private

        def _quote(value)
          case value
          when Type::Binary::Data
            "0x#{value.hex}"
          when ActiveRecord::Type::SQLServer::Data
            value.quoted
          when String, ActiveSupport::Multibyte::Chars
            "#{QUOTED_STRING_PREFIX}#{super}"
          else
            super
          end
        end

        def _type_cast(value)
          case value
          when ActiveRecord::Type::SQLServer::Data
            value.to_s
          else
            super
          end
        end
      end
    end
  end
end
