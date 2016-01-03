module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition

        def primary_key(name, type = :primary_key, options = {})
          return super unless type == :uuid
          options[:default] = options.fetch(:default, 'NEWID()')
          options[:primary_key] = true
          column name, type, options
        end

        def real(name, options = {})
          column(name, :real, options)
        end

        def money(name, options = {})
          column(name, :money, options)
        end

        def datetime2(name, options = {})
          column(name, :datetime2, options)
        end

        def datetimeoffset(name, options = {})
          column(name, :datetimeoffset, options)
        end

        def smallmoney(name, options = {})
          column(name, :smallmoney, options)
        end

        def char(name, options = {})
          column(name, :char, options)
        end

        def varchar(name, options = {})
          column(name, :varchar, options)
        end

        def varchar_max(name, options = {})
          column(name, :varchar_max, options)
        end

        def text_basic(name, options = {})
          column(name, :text_basic, options)
        end

        def nchar(name, options = {})
          column(name, :nchar, options)
        end

        def ntext(name, options = {})
          column(name, :ntext, options)
        end

        def binary_basic(name, options = {})
          column(name, :binary_basic, options)
        end

        def varbinary(name, options = {})
          column(name, :varbinary, options)
        end

        def uuid(name, options = {})
          column(name, :uniqueidentifier, options)
        end

        def ss_timestamp(name, options = {})
          column(name, :ss_timestamp, options)
        end

      end
    end
  end
end
