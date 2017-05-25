
## Rails v5.1

* BIGINT PK support. https://github.com/rails/rails/pull/26266
* Raise `ActiveRecord::NotNullViolation` when a record cannot be inserted
  or updated because it would violate a not null constraint.
* Raise `ActiveRecord::RangeError` when values that executed are out of range.
* Allow passing extra flags to `db:structure:load` and `db:structure:dump`
  Introduces `ActiveRecord::Tasks::DatabaseTasks.structure_(load|dump)_flags` to customize the
  eventual commands run against the database, e.g. mysqldump/pg_dump.
* Set `:time` as a timezone aware type and remove deprecation when
  `config.active_record.time_zone_aware_types` is not explicitly set.
* Remove deprecated support to passing a column to `#quote`.
* `#tables` and `#table_exists?` return only tables and not views.
  All the deprecations on those methods were removed.
* Remove deprecated `original_exception` argument in `ActiveRecord::StatementInvalid#initialize`
  and `ActiveRecord::StatementInvalid#original_exception`.
* Remove deprecated tasks: `db:test:clone`, `db:test:clone_schema`, `db:test:clone_structure`.
* Make `table_name=` reset current statement cache,
  so queries are not run against the previous table name.
* Deprecate using `#quoted_id` in quoting.
* Deprecate `supports_migrations?` on connection adapters.
* Dig moving `Column#sqlserver_options` to `sql_type_metadata` delegate.
* Should we do like PG and add `options[:collation]` before `#add_column_options!`?
* Translated exceptions: `SerializationFailure` and `RangeError`.
