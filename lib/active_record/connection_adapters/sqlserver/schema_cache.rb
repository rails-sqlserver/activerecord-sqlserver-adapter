module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaCache < ActiveRecord::ConnectionAdapters::SchemaCache

        attr_reader :view_information

        def initialize(conn)
          super
          @table_names = nil
          @view_names = nil
          @view_information = {}
        end

        # Superclass Overrides

        def table_exists?(table_name)
          return false if table_name.blank?
          key = table_name_key(table_name)
          return @tables[key] if @tables.key? key
          @tables[key] = connection.table_exists?(table_name)
        end

        def clear!
          super
          @table_names = nil
          @view_names = nil
          @view_information.clear
        end

        def clear_table_cache!(table_name)
          key = table_name_key(table_name)
          super(key)
          super(table_name)
          # SQL Server Specific
          if @table_names
            @table_names.delete key
            @table_names.delete table_name
          end
          if @view_names
            @view_names.delete key
            @view_names.delete table_name
          end
          @view_information.delete key
        end

        # SQL Server Specific

        def table_names
          @table_names ||= connection.tables
        end

        def view_names
          @view_names ||= connection.views
        end

        def view_exists?(table_name)
          table_exists?(table_name)
        end

        def view_information(table_name)
          key = table_name_key(table_name)
          return @view_information[key] if @view_information.key? key
          @view_information[key] = connection.send(:view_information, table_name)
        end


        private

        def table_name_key(table_name)
          SQLServer::Utils.extract_identifiers(table_name).object
        end

      end
    end
  end
end
