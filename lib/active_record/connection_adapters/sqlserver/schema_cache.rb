module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaCache < ActiveRecord::ConnectionAdapters::SchemaCache

        def initialize(conn)
          super
          @views = {}
          @view_information = {}
        end

        # Superclass Overrides

        def primary_keys(table_name)
          name = key(table_name)
          @primary_keys[name] ||= table_exists?(table_name) ? connection.primary_key(table_name) : nil
        end

        def table_exists?(table_name)
          name = key(table_name)
          prepare_tables_and_views
          return @tables[name] if @tables.key? name
          table_exists = @tables[name] = connection.table_exists?(table_name)
          table_exists || view_exists?(table_name)
        end

        def tables(name)
          super(key(name))
        end

        def columns(table_name)
          name = key(table_name)
          @columns[name] ||= connection.columns(table_name)
        end

        def columns_hash(table_name)
          name = key(table_name)
          @columns_hash[name] ||= Hash[columns(table_name).map { |col|
            [col.name, col]
          }]
        end

        def clear!
          super
          @views.clear
          @view_information.clear
        end

        def size
          super + [@views, @view_information].map{ |x| x.size }.inject(:+)
        end

        def clear_table_cache!(table_name)
          name = key(table_name)
          @columns.delete name
          @columns_hash.delete name
          @primary_keys.delete name
          @tables.delete name
          @views.delete name
          @view_information.delete name
        end

        def marshal_dump
          super + [@views, @view_information]
        end

        def marshal_load(array)
          @views, @view_information = array[-2..-1]
          super(array[0..-3])
        end

        # SQL Server Specific

        def view_exists?(table_name)
          name = key(table_name)
          prepare_tables_and_views
          return @views[name] if @views.key? name
          @views[name] = connection.views.include?(table_name)
        end

        def view_information(table_name)
          name = key(table_name)
          return @view_information[name] if @view_information.key? name
          @view_information[name] = connection.send(:view_information, table_name)
        end


        private

        def identifier(table_name)
          SQLServer::Utils.extract_identifiers(table_name)
        end

        def key(table_name)
          identifier(table_name).quoted
        end

        def prepare_tables_and_views
          prepare_views if @views.empty?
          prepare_tables if @tables.empty?
        end

        def prepare_tables
          connection.tables.each { |table| @tables[key(table)] = true }
        end

        def prepare_views
          connection.views.each { |view| @views[key(view)] = true }
        end

      end
    end
  end
end
