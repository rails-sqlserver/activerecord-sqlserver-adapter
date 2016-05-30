## v4.2.15

#### Fixed

* Removed errand puts statment from database tasks.
* Fix quoting of non-national columns.


## v4.2.14

#### Fixed

* Fix rescue constants for optional connection gems. Fixes #475.


## v4.2.13

#### Fixed

* Add to_s method to SQLServer::Type::Char::Data. Thanks @marceloeloelo.


## v4.2.12

#### Fixed

* Isolation levels not being reset on error. Fixes #469. Thanks @anthony


## v4.2.11

#### Fixed

* Undefined method `database_prefix_remote_server?' Fixes #450. Thanks @jippeholwerda
* Document two methods for avoiding N'' quoting on char/varchar columns.
* First run failure of `change_column` while dropping constraint. Fixes #420. Thanks @GrumpyRainbow @rkr090
* Rounding errors w/datetime2(0) types having no fractional seconds. Fixes #465. Thanks @alawton

#### Changed

* Supporting escape hatch for N'' quoting. Remove `#is_utf8` string check in `#_quote` method.
  This duplicated strings and forced encoding which was actually wasteful.


## v4.2.10

#### Fixed

* Ensure small datetime/datetime2 fractionals are properly quoted. Fixes #457.


## v4.2.9

#### Fixed

* Conform to new data_sources interfaces. See: https://git.io/va4Fp
* The `primary_key` method falls back to Identity columns. Not the other way around. Fixes #454. Thanks @marceloeloelo
* Ensure that `execute_procedure` returns proper time zones. Fixes #449

#### Changed

* Run tests with verbose false.


## v4.2.8

#### Fixed

* Azure-Friendly Disable Referential Integrity. No more `sp_MSforeachtable` usage. Fixes #421
* Azure-Friendly DB create/drop. Fixes #442
  - Create allows edition options like: MAXSIZE, EDITION, and SERVICE_OBJECTIVE.


## v4.2.7

#### Added

* Support 2008 Datatypes Using TDSVER=7.3. Fixes #433

#### Changed

* Test now use latest v0.9.5 of TinyTDS. Includes tests for `defncopy` Windows binstub.
* Make linked servers stronger. Fixes #427. Thanks @jippeholwerda
* Use proper module for the `sqlserver_connection` method. Fixes #431. Thanks @jippeholwerda
* All datetime casting using the `Time::DATE_FORMATS[:_sqlserver_*]` formats set after connection.

#### Removed

* The `SQLServer::Utils.with_sqlserver_db_date_formats` helper and `quoted_date` hacks.
* The `Quoter` value type which allowed column => type special case quoting.

#### Fixed

* Every time datatype has perfect micro/nano second handling.
* All supported datatypes dump defaults properly to schema.rb
* Partial indexes using `:where` in schema dumper. Fixes #153


## v4.2.6

#### Fixed

* Allow linked servers for table names. Fixes #426. Thanks @jippeholwerda


## v4.2.5

#### Removed

* Remove Type::Castable hacks for core type objects to force trust the DB. Allows Rails 5 attributes.

#### Fixed

* Tests for decimal scale. See Rails commit. http://git.io/vGotB
* Improve case comparision performace per column. Fixes #414
* DB rollback when reversable add_column has several options. Fixes #359
* Better column definitions for default objects. Fixes #412


## v4.2.4

#### Fixed

* Compatible with Rails 4.2.1.
* Fix schema limit reflection for char/varchar. Fixes #394.


## v4.2.3

#### Fixed

* Fix SET defaults when using Azure.
* Test insert 4-byte unicode chars.
* Make rollback transaction transcount aware for implicit error rollbacks. Fixes #390


## v4.2.2

#### Added

* DatabaseTasks support for all tasks! Uses FreeTDS `defncopy` for structure dump. Fixes #380.
* Provide class config for `use_output_inserted` (default true) for insert SQL. Fixed #381.


## v4.2.1

#### Fixed

* Guard against empty view definitions when `sb_helptext` fails silently. Fixes #337.
* Proper table/column escaping in the `change_column_null` method. Fixes #355.
* Use `send :include` for modules for 1.9 compatibility. Fixes #383.


## v4.2.0

#### Added

* New `ActiveRecord::Type` objects. See `active_record/connection_adapters/sqlserver/type` dir.
* Aliased `ActiveRecord::Type::SQLServer` to `ActiveRecord::ConnectionAdapters::SQLServer::Type`
* New `SQLServer::Utils::Name` object for decomposing and quoting SQL Server names/identifiers.
* Support for most all SQL Server types in schema statements and dumping.
* Support create table with query from relation or select statement.
* Foreign Key Support Fixes #375.

#### Changed

* The `create_database` now takes an options hash. Only key/value now is `collation`. Unknown keys just use raw values for SQL.
* Complete rewrite of our Arel visitor. Focuing on 2012 and upward so we can make FETCH happen.
* Testing enhancements.
  * Guard support, check our Guardfile.
  * Use `ARTest` namespace with `SQLServer` module for our helpers/objects.
  * Simple 2012 schmea addition and extensive column/type_cast object tests.
* Follow Rails convention and remove varying character default limits.
* The `cs_equality_operator` is now s class configuration property only.
* The `with_identity_insert_enabled(table_name)` is now public.
* Use ActiveRecord tranasaction interface vs our own `run_with_isolation_level`.

#### Deprecated

* n/a

#### Removed

* SQL Server versions < 2012 which do not support OFFSET and FETCH. http://bit.ly/1B5Bwsd
* The `enable_default_unicode_types` option. Default to national types all the time.
* Native type configs for older DB support. Includes the following with new default value:
  * native_string_database_type => `nvarchar`
  * native_text_database_type   => `nvarchar(max)`
  * native_binary_database_type => `varbinary(max)`
* Various version and inspection methods removed. These include:
  * database_version
  * database_year
  * product_level
  * product_version
  * edition
* Removed tests for old issue #164. Handled by core types now.
* The `activity_stats` method. Please put this in a gem if needed.
* We no longer use regular expressions to fix identity inserts. Use ActiveRecord or public ID insert helper.
* All auto reconnect and SQL retry logic. Got too complicated and stood in the way of AR's pool. Speed boost too.
* The adapter will no longer try to remove duplicate order by clauses. Use relation `reorder`, `unscope`, etc.
* We no longer use regular expressions to remove identity columns from updates. Now with `attributes_for_update` AR hook.

#### Fixed

* Default lock is now "WITH(UPDLOCK)". Fixes #368
* Better bind types & params for `sp_executesql`. Fixes #239.

#### Security

* The connection's `inspect` method no longer returns sensitive connection info. Very basic now.


