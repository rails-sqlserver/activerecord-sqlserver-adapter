module ActiveRecord
  module ConnectionAdapters
    module SQLServer

      module ColumnMethods

        def primary_key(name, type = :primary_key, **options)
          return super unless type == :uuid
          options[:default] = options.fetch(:default, 'NEWID()')
          options[:primary_key] = true
          column name, type, options
        end

        def primary_key_nonclustered(*args, **options)
          args.each { |name| column(name, :primary_key_nonclustered, options) }
        end

        def real(*args, **options)
          args.each { |name| column(name, :real, options) }
        end

        def money(*args, **options)
          args.each { |name| column(name, :money, options) }
        end

        def datetime(*args, **options)
          args.each do |name|
            if options[:precision]
              datetime2(name, options)
            else
              column(name, :datetime, options)
            end
          end
        end

        def datetime2(*args, **options)
          args.each { |name| column(name, :datetime2, options) }
        end

        def datetimeoffset(*args, **options)
          args.each { |name| column(name, :datetimeoffset, options) }
        end

        def smallmoney(*args, **options)
          args.each { |name| column(name, :smallmoney, options) }
        end

        def char(*args, **options)
          args.each { |name| column(name, :char, options) }
        end

        def varchar(*args, **options)
          args.each { |name| column(name, :varchar, options) }
        end

        def varchar_max(*args, **options)
          args.each { |name| column(name, :varchar_max, options) }
        end

        def text_basic(*args, **options)
          args.each { |name| column(name, :text_basic, options) }
        end

        def nchar(*args, **options)
          args.each { |name| column(name, :nchar, options) }
        end

        def ntext(*args, **options)
          args.each { |name| column(name, :ntext, options) }
        end

        def binary_basic(*args, **options)
          args.each { |name| column(name, :binary_basic, options) }
        end

        def varbinary(*args, **options)
          args.each { |name| column(name, :varbinary, options) }
        end

        def uuid(*args, **options)
          args.each { |name| column(name, :uniqueidentifier, options) }
        end

        def ss_timestamp(*args, **options)
          args.each { |name| column(name, :ss_timestamp, options) }
        end

      end

      class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition
        include ColumnMethods

        def new_column_definition(name, type, options)
          type = :datetime2 if type == :datetime && options[:precision]
          super name, type, options
        end
      end

      class Table < ActiveRecord::ConnectionAdapters::Table
        include ColumnMethods
      end
    end
  end
end
