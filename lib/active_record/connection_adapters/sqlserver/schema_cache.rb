module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaCache < ActiveRecord::ConnectionAdapters::SchemaCache

        def initialize(conn)
          super
          @views = {}
          @view_information = {}
        end

        def initialize_dup(other)
          super
          @views = @views.dup
          @view_information = @view_information.dup
        end

        def primary_keys(table_name)
          super tn_quoted(table_name)
        end

        def data_source_exists?(table_name)
          super tn_quoted(table_name)
        end

        def add(table_name)
          super tn_quoted(table_name)
        end

        def data_sources(name)
          super tn_quoted(name)
        end

        # No override for #columns.
        # Allow `table_name` which could be fully qualified to be used with schema reflection.

        def columns_hash(table_name)
          super tn_quoted(table_name)
        end

        def clear!
          super
          @views.clear
          @view_information.clear
        end

        def size
          super + [@views, @view_information].map{ |x| x.size }.inject(:+)
        end

        def clear_data_source_cache!(table_name)
          name = tn_quoted(table_name)
          super(name)
          @columns.delete table_name # Because...
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
          prepare_data_sources if @views.empty?
          name = tn_quoted(table_name)
          return @views[name] if @views.key? name
          @views[name] = connection.views.include?(tn_object(table_name))
        end

        def view_information(table_name)
          name = tn_quoted(table_name)
          return @view_information[name] if @view_information.key? name
          @view_information[name] = connection.send(:view_information, table_name)
        end


        private

        def identifier(table_name)
          SQLServer::Utils.extract_identifiers(table_name)
        end

        def tn_quoted(table_name)
          identifier(table_name).quoted
        end

        def tn_object(table_name)
          identifier(table_name).object
        end

        def prepare_data_sources
          connection.data_sources.each { |source| @data_sources[tn_quoted(source)] = true }
          connection.views.each { |source| @views[tn_quoted(source)] = true }
        end

      end
    end
  end
end
