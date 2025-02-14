# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaCreation < SchemaCreation
        private

        delegate :quoted_include_columns_for_index, to: :@conn

        def supports_index_using?
          false
        end

        def visit_TableDefinition(o)
          if_not_exists = o.if_not_exists

          if o.as
            table_name = quote_table_name(o.temporary ? "##{o.name}" : o.name)
            query = o.as.respond_to?(:to_sql) ? o.as.to_sql : o.as
            projections, source = query.match(%r{SELECT\s+(.*)?\s+FROM\s+(.*)?}).captures
            sql = "SELECT #{projections} INTO #{table_name} FROM #{source}"
          else
            o.instance_variable_set :@as, nil
            o.instance_variable_set :@if_not_exists, false
            sql = super
          end

          if if_not_exists
            o.instance_variable_set :@if_not_exists, true
            table_name = o.temporary ? "##{o.name}" : o.name
            sql = "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='#{table_name}' and xtype='U') #{sql}"
          end

          sql
        end

        def visit_CreateIndexDefinition(o)
          index = o.index

          sql = []
          sql << "IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = '#{o.index.name}')" if o.if_not_exists
          sql << "CREATE"
          sql << "UNIQUE" if index.unique
          sql << index.type.upcase if index.type
          sql << "INDEX"
          sql << "#{quote_column_name(index.name)} ON #{quote_table_name(index.table)}"
          sql << "(#{quoted_columns(index)})"
          sql << "INCLUDE (#{quoted_include_columns(index.include)})" if supports_index_include? && index.include
          sql << "WHERE #{index.where}" if index.where

          sql.join(" ")
        end

        def quoted_include_columns(o)
          (String === o) ? o : quoted_include_columns_for_index(o)
        end

        def add_column_options!(sql, options)
          sql << " DEFAULT #{quote_default_expression_for_column_definition(options[:default], options[:column])}" if options_include_default?(options)
          if options[:collation].present?
            sql << " COLLATE #{options[:collation]}"
          end
          if options[:null] == false
            sql << " NOT NULL"
          end
          if options[:is_identity] == true
            sql << " IDENTITY(1,1)"
          end
          if options[:primary_key] == true
            sql << " PRIMARY KEY"
          end
          sql
        end

        def action_sql(action, dependency)
          case dependency
          when :restrict
            raise ArgumentError, <<~MSG.squish
              '#{dependency}' is not supported for :on_update or :on_delete.
              Supported values are: :nullify, :cascade
            MSG
          else
            super
          end
        end

        def options_include_default?(options)
          super || options_primary_key_with_nil_default?(options)
        end

        def options_primary_key_with_nil_default?(options)
          options[:primary_key] && options.include?(:default) && options[:default].nil?
        end
      end
    end
  end
end
