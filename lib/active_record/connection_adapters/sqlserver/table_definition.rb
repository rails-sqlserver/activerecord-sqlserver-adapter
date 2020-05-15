# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module ColumnMethods
        def primary_key(name, type = :primary_key, **options)
          if [:integer, :bigint].include?(type)
            options[:is_identity] = true unless options.key?(:default)
          elsif type == :uuid
            options[:default] = options.fetch(:default, "NEWID()")
            options[:primary_key] = true
          end
          super
        end

        def primary_key_nonclustered(*names, **options)
          names.each { |name| column(name, :primary_key_nonclustered, **options) }
        end

        def real(*names, **options)
          names.each { |name| column(name, :real, **options) }
        end

        def money(*names, **options)
          names.each { |name| column(name, :money, **options) }
        end

        def smalldatetime(*names, **options)
          names.each { |name| column(name, :smalldatetime, **options) }
        end

        def datetime(*names, **options)
          names.each do |name|
            if options[:precision]
              datetime2(name, **options)
            else
              column(name, :datetime, **options)
            end
          end
        end

        def datetime2(*names, **options)
          names.each { |name| column(name, :datetime2, **options) }
        end

        def datetimeoffset(*names, **options)
          names.each { |name| column(name, :datetimeoffset, **options) }
        end

        def smallmoney(*names, **options)
          names.each { |name| column(name, :smallmoney, **options) }
        end

        def char(*names, **options)
          names.each { |name| column(name, :char, **options) }
        end

        def varchar(*names, **options)
          names.each { |name| column(name, :varchar, **options) }
        end

        def varchar_max(*names, **options)
          names.each { |name| column(name, :varchar_max, **options) }
        end

        def text_basic(*names, **options)
          names.each { |name| column(name, :text_basic, **options) }
        end

        def nchar(*names, **options)
          names.each { |name| column(name, :nchar, **options) }
        end

        def ntext(*names, **options)
          names.each { |name| column(name, :ntext, **options) }
        end

        def binary_basic(*names, **options)
          names.each { |name| column(name, :binary_basic, **options) }
        end

        def varbinary(*names, **options)
          names.each { |name| column(name, :varbinary, **options) }
        end

        def uuid(*names, **options)
          names.each { |name| column(name, :uniqueidentifier, **options) }
        end

        def ss_timestamp(*names, **options)
          names.each { |name| column(name, :ss_timestamp, **options) }
        end

        def json(*names, **options)
          names.each { |name| column(name, :text, **options) }
        end
      end

      class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition
        include ColumnMethods

        def new_column_definition(name, type, **options)
          case type
          when :datetime
            type = :datetime2 if options[:precision]
          when :primary_key
            options[:is_identity] = true
          end
          super
        end
      end

      class Table < ActiveRecord::ConnectionAdapters::Table
        include ColumnMethods
      end
    end
  end
end
