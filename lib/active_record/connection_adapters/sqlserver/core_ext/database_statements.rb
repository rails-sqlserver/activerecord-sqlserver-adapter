module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module CoreExt
        module DatabaseStatements
          
          # This is a copy of the current (3.1.3) ActiveRecord's transaction method. We should propose
          # a patch to the default transaction method to make it more callback for adapters that want to 
          # do deadlock retry logic. Because this is a copy, we really need to keep an eye out on this when
          # upgradding the adapter. 
          def transaction_with_retry_deadlock_victim(options = {})
            options.assert_valid_keys :requires_new, :joinable

            last_transaction_joinable = defined?(@transaction_joinable) ? @transaction_joinable : nil
            if options.has_key?(:joinable)
              @transaction_joinable = options[:joinable]
            else
              @transaction_joinable = true
            end
            requires_new = options[:requires_new] || !last_transaction_joinable

            transaction_open = false
            @_current_transaction_records ||= []

            begin
              if block_given?
                if requires_new || open_transactions == 0
                  if open_transactions == 0
                    begin_db_transaction
                  elsif requires_new
                    create_savepoint
                  end
                  increment_open_transactions
                  transaction_open = true
                  @_current_transaction_records.push([])
                end
                yield
              end
            rescue Exception => database_transaction_rollback
              if transaction_open && !outside_transaction?
                transaction_open = false
                decrement_open_transactions
                # handle deadlock victim retries at the outermost transaction
                if open_transactions == 0
                  if database_transaction_rollback.is_a?(::ActiveRecord::DeadlockVictim)
                    # SQL Server has already rolled back, so rollback activerecord's history
                    rollback_transaction_records(true)
                    retry
                  else
                    rollback_db_transaction
                    rollback_transaction_records(true)
                  end
                else
                  rollback_to_savepoint
                  rollback_transaction_records(false)
                end
              end
              raise unless database_transaction_rollback.is_a?(::ActiveRecord::Rollback)
            end
          ensure
            @transaction_joinable = last_transaction_joinable

            if outside_transaction?
              @open_transactions = 0
            elsif transaction_open
              decrement_open_transactions
              begin
                if open_transactions == 0
                  commit_db_transaction
                  commit_transaction_records
                else
                  release_savepoint
                  save_point_records = @_current_transaction_records.pop
                  unless save_point_records.blank?
                    @_current_transaction_records.push([]) if @_current_transaction_records.empty?
                    @_current_transaction_records.last.concat(save_point_records)
                  end
                end
              rescue Exception => database_transaction_rollback
                if open_transactions == 0
                  rollback_db_transaction
                  rollback_transaction_records(true)
                else
                  rollback_to_savepoint
                  rollback_transaction_records(false)
                end
                raise
              end
            end
          end
          
        end
      end
    end
  end
end

