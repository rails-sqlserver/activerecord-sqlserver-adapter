# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SqlTypeMetadata < ActiveRecord::ConnectionAdapters::SqlTypeMetadata
        def initialize(**kwargs)
          @sqlserver_options = kwargs.extract!(:sqlserver_options)
          super(**kwargs)
        end

        protected

        def attributes_for_hash
          super + [@sqlserver_options]
        end
      end
    end
  end
end
