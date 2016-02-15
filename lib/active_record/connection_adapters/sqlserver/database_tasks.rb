module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module DatabaseTasks

        def create_database(database, options = {})
          name = SQLServer::Utils.extract_identifiers(database)
          db_options = create_database_options(options)
          edition_options = create_database_edition_options(options)
          do_execute "CREATE DATABASE #{name} #{db_options} #{edition_options}"
        end

        def drop_database(database)
          name = SQLServer::Utils.extract_identifiers(database)
          do_execute "DROP DATABASE #{name}"
        end

        def current_database
          select_value 'SELECT DB_NAME()'
        end

        def charset
          select_value "SELECT DATABASEPROPERTYEX(DB_NAME(), 'SqlCharSetName')"
        end

        def collation
          select_value "SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation')"
        end


        private

        def create_database_options(options={})
          keys  = [:collate]
          copts = @connection_options
          options = {
            collate: copts[:collation]
          }.merge(options.symbolize_keys).select { |_, v|
            v.present?
          }.slice(*keys).map { |k,v|
            "#{k.to_s.upcase} #{v}"
          }.join(' ')
          options
        end

        def create_database_edition_options(options={})
          keys  = [:maxsize, :edition, :service_objective]
          copts = @connection_options
          edition_options = {
            maxsize: copts[:azure_maxsize],
            edition: copts[:azure_edition],
            service_objective: copts[:azure_service_objective]
          }.merge(options.symbolize_keys).select { |_, v|
            v.present?
          }.slice(*keys).map { |k,v|
            "#{k.to_s.upcase} = #{v}"
          }.join(', ')
          edition_options = "( #{edition_options} )" if edition_options.present?
          edition_options
        end

      end
    end
  end
end



