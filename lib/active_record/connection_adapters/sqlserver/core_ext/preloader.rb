# frozen_string_literal: true

require "active_record/associations/preloader"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Preloader
          private

          def records_for(ids)
            ids.each_slice(in_clause_length).flat_map do |slice|
              scope.where(association_key_name => slice).load do |record|
                # Processing only the first owner
                # because the record is modified but not an owner
                owner = owners_by_key[convert_key(record[association_key_name])].first
                association = owner.association(reflection.name)
                association.set_inverse_instance(record)
              end.records
            end
          end

          def in_clause_length
            10_000
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  mod = ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Preloader
  ActiveRecord::Associations::Preloader::Association.prepend(mod)
end
