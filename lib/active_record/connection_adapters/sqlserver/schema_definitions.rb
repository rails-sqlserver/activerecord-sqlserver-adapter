# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class IndexDefinition < ActiveRecord::ConnectionAdapters::IndexDefinition # :nodoc:
        attr_reader :type, :include

        def initialize(*args, type: nil, include: nil, **kwargs)
          super(*args, **kwargs)
          @type = type
          @include = include
        end

        def as_schema_json
          json = super
          json["type"] = @type
          json["include"] = @include
          json
        end

        def init_from_schema_json(coder, references)
          super
          @type = coder["type"]&.to_sym
          @include = coder["include"]
        end
      end
    end
  end
end
