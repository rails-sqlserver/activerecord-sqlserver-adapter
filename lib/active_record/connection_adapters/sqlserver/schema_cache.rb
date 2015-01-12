module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaCache < ActiveRecord::ConnectionAdapters::SchemaCache

        attr_reader :view_information

        def initialize(conn)
          super
          @views = {}
          @view_information = {}
        end

        # Superclass Overrides

        def primary_keys(table_name)
          super(table_name_key(table_name))
        end

        def table_exists?(table_name)
          name = table_name_key(table_name)
          super(name) || view_exists?(name)
        end

        def add(table_name)
          super(table_name_key(table_name))
        end

        def tables(name)
          super(table_name_key(name))
        end

        def columns(table_name)
          super(table_name_key(table_name))
        end

        def columns_hash(table_name)
          super(table_name_key(table_name))
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
          table_name = table_name_key(table_name)
          super(table_name)
          @views.delete table_name
          @view_information.delete table_name
        end

        def marshal_dump
          super + [@views, @view_information]
        end

        def marshal_load(array)
          @views, @view_information = array[-2..-1]
          super(array[0..-3])
        end

        # SQL Server Specific

        def view_names
          @views.select{ |k,v| v }.keys
        end

        def view_exists?(table_name)
          name = table_name_key(table_name)
          prepare_views if @views.empty?
          return @views[name] if @views.key? name
          @views[name] = connection.views.include?(name)
        end

        def view_information(table_name)
          name = table_name_key(table_name)
          return @view_information[name] if @view_information.key? name
          @view_information[name] = connection.send(:view_information, table_name)
        end


        private

        def table_name_key(table_name)
          SQLServer::Utils.extract_identifiers(table_name).quoted
        end

        def prepare_views
          connection.views.each { |view| @views[view] = true }
        end

      end
    end
  end
end
