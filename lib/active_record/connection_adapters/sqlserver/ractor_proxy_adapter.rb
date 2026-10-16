# frozen_string_literal: true

# :markup: markdown

require "active_record/connection_adapters/ractor_connection_handler/abstract_proxy_adapter"

module ActiveRecord
  module ConnectionAdapters
    class RactorConnectionHandler # :nodoc:
      class SQLServerProxyAdapter < AbstractProxyAdapter # :nodoc:
        def disable_referential_integrity
          tables = tables_with_referential_integrity
          tables.each { |t| execute "ALTER TABLE #{quote_table_name(t)} NOCHECK CONSTRAINT ALL" }

          begin
            yield
          ensure
            tables.each { |t| execute "ALTER TABLE #{quote_table_name(t)} CHECK CONSTRAINT ALL" }
          end
        end

        def create_savepoint(name = current_savepoint_name)
          query_command("SAVE TRANSACTION #{name}", "TRANSACTION")
        end

        def exec_rollback_to_savepoint(name = current_savepoint_name)
          query_command("ROLLBACK TRANSACTION #{name}", "TRANSACTION")
        end

        def release_savepoint(_name = current_savepoint_name)
          # SQL Server does not require savepoints to be explicitly released.
        end

        # CAPABILITIES ============================================

        def supports_advisory_locks?
          pure_remote_dispatch(:supports_advisory_locks?)
        end

        def supports_bulk_alter?
          pure_remote_dispatch(:supports_bulk_alter?)
        end

        def supports_check_constraints?
          pure_remote_dispatch(:supports_check_constraints?)
        end

        def supports_comments?
          pure_remote_dispatch(:supports_comments?)
        end

        def supports_comments_in_create?
          pure_remote_dispatch(:supports_comments_in_create?)
        end

        def supports_common_table_expressions?
          pure_remote_dispatch(:supports_common_table_expressions?)
        end

        def supports_ddl_transactions?
          pure_remote_dispatch(:supports_ddl_transactions?)
        end

        def supports_explain?
          pure_remote_dispatch(:supports_explain?)
        end

        def supports_expression_index?
          pure_remote_dispatch(:supports_expression_index?)
        end

        def supports_foreign_keys?
          pure_remote_dispatch(:supports_foreign_keys?)
        end

        def supports_index_include?
          pure_remote_dispatch(:supports_index_include?)
        end

        def supports_index_sort_order?
          pure_remote_dispatch(:supports_index_sort_order?)
        end

        def supports_indexes_in_create?
          pure_remote_dispatch(:supports_indexes_in_create?)
        end

        def supports_insert_conflict_target?
          pure_remote_dispatch(:supports_insert_conflict_target?)
        end

        def supports_insert_on_duplicate_skip?
          pure_remote_dispatch(:supports_insert_on_duplicate_skip?)
        end

        def supports_insert_on_duplicate_update?
          pure_remote_dispatch(:supports_insert_on_duplicate_update?)
        end

        def supports_insert_returning?
          pure_remote_dispatch(:supports_insert_returning?)
        end

        def supports_json?
          pure_remote_dispatch(:supports_json?)
        end

        def supports_lazy_transactions?
          pure_remote_dispatch(:supports_lazy_transactions?)
        end

        def supports_optimizer_hints?
          pure_remote_dispatch(:supports_optimizer_hints?)
        end

        def supports_partial_index?
          pure_remote_dispatch(:supports_partial_index?)
        end

        def supports_savepoints?
          pure_remote_dispatch(:supports_savepoints?)
        end

        def supports_transaction_isolation?
          pure_remote_dispatch(:supports_transaction_isolation?)
        end

        def supports_views?
          pure_remote_dispatch(:supports_views?)
        end

        def supports_virtual_columns?
          pure_remote_dispatch(:supports_virtual_columns?)
        end

        # QUOTING =================================================

        def quote(...)
          pure_remote_dispatch(:quote, ...)
        end

        def quote_default_expression(...)
          pure_remote_dispatch(:quote_default_expression, ...)
        end

        def quote_string(...)
          pure_remote_dispatch(:quote_string, ...)
        end

        def quote_table_name_for_assignment(...)
          pure_remote_dispatch(:quote_table_name_for_assignment, ...)
        end

        def quoted_binary(...)
          pure_remote_dispatch(:quoted_binary, ...)
        end

        def quoted_date(...)
          pure_remote_dispatch(:quoted_date, ...)
        end

        def type_cast(...)
          remote_dispatch(:type_cast, ...)
        end

        def unquoted_false
          remote_dispatch(:unquoted_false)
        end

        def unquoted_true
          remote_dispatch(:unquoted_true)
        end

        # DATABASE STATEMENTS =====================================

        def default_insert_value(...)
          remote_dispatch(:default_insert_value, ...)
        end

        def apply_returning_to!(intent, returning)
          # SQL Server does not support the RETURNING syntax. Returning is
          # handled on the main connection via OUTPUT / SCOPE_IDENTITY, so
          # replicate that here on the worker instead of appending RETURNING.
          return unless supports_insert_returning?

          intent.raw_sql = "#{intent.raw_sql}; SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident"
        end

        def high_precision_current_timestamp
          remote_dispatch(:high_precision_current_timestamp)
        end

        def write_query?(...)
          remote_dispatch(:write_query?, ...)
        end

        # SCHEMA STATEMENTS =======================================

        def add_column(...)
          remote_dispatch(:add_column, ...)
        end

        def add_foreign_key(...)
          remote_dispatch(:add_foreign_key, ...)
        end

        def add_index(...)
          remote_dispatch(:add_index, ...)
        end

        def change_column(...)
          remote_dispatch(:change_column, ...)
        end

        def change_column_default(...)
          remote_dispatch(:change_column_default, ...)
        end

        def change_column_null(...)
          remote_dispatch(:change_column_null, ...)
        end

        def check_constraints(...)
          remote_dispatch(:check_constraints, ...)
        end

        def columns_for_distinct(...)
          remote_dispatch(:columns_for_distinct, ...)
        end

        def create_schema_dumper(options)
          SQLServer::SchemaDumper.create(self, options)
        end

        def default_sequence_name(...)
          remote_dispatch(:default_sequence_name, ...)
        end

        def drop_table(...)
          remote_dispatch(:drop_table, ...)
        end

        def foreign_keys(...)
          remote_dispatch(:foreign_keys, ...)
        end

        def index_name(...)
          remote_dispatch(:index_name, ...)
        end

        def index_name_exists?(...)
          remote_dispatch(:index_name_exists?, ...)
        end

        def remove_column(...)
          remote_dispatch(:remove_column, ...)
        end

        def remove_foreign_key(...)
          remote_dispatch(:remove_foreign_key, ...)
        end

        def remove_index(...)
          remote_dispatch(:remove_index, ...)
        end

        def rename_column(...)
          remote_dispatch(:rename_column, ...)
        end

        def rename_index(...)
          remote_dispatch(:rename_index, ...)
        end

        def rename_table(...)
          remote_dispatch(:rename_table, ...)
        end

        def table_comment(...)
          remote_dispatch(:table_comment, ...)
        end

        def type_to_sql(...)
          pure_remote_dispatch(:type_to_sql, ...)
        end

        def update_table_definition(...)
          remote_dispatch(:update_table_definition, ...)
        end

        # ADAPTER SPECIFIC ========================================

        def get_database_version
          remote_dispatch(:get_database_version)
        end

        def quoted_scope(...)
          pure_remote_dispatch(:quoted_scope, ...)
        end

        private
          # SCHEMA STATEMENTS =======================================

          def add_options_for_index_columns(...)
            remote_dispatch(:add_options_for_index_columns, ...)
          end

          def change_column_comment_sql(...)
            remote_dispatch(:change_column_comment_sql, ...)
          end

          def change_index_comment_sql(...)
            remote_dispatch(:change_index_comment_sql, ...)
          end

          def change_table_comment_sql(...)
            remote_dispatch(:change_table_comment_sql, ...)
          end

          def create_alter_table(...)
            remote_dispatch(:create_alter_table, ...)
          end

          def data_source_sql(...)
            remote_dispatch(:data_source_sql, ...)
          end

          def drop_table_sql(...)
            remote_dispatch(:drop_table_sql, ...)
          end

          def extract_foreign_key_action(...)
            remote_dispatch(:extract_foreign_key_action, ...)
          end

          def fetch_table_options(...)
            remote_dispatch(:fetch_table_options, ...)
          end

          def fetch_type_metadata(...)
            remote_dispatch(:fetch_type_metadata, ...)
          end

          def reference_name_for_table(...)
            remote_dispatch(:reference_name_for_table, ...)
          end

          def validate_table_length!(...)
            remote_dispatch(:validate_table_length!, ...)
          end

          # ADAPTER SPECIFIC ========================================

          def can_perform_case_insensitive_comparison_for?(...)
            pure_remote_dispatch(:can_perform_case_insensitive_comparison_for?, ...)
          end

          def warning_ignored?(...)
            remote_dispatch(:warning_ignored?, ...)
          end
      end
    end
  end
end
