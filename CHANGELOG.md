## v5.2.1

#### Fixed

- [#691](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/691) Fix constraints bug
- [#700](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/700) SET SINGLE_USER before dropping the database
- [#733](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/733) Calculate should not remove ordering for MSSQL
- [#735](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/735) Order by selected items when using distinct exists
- [#737](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/737) Use default precision for 'time' column type
- [#744](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/744) Adapter does not use prepared statement cache
- [#743](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/743) Set default time precision when registering time type
- [#745](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/745) Quoted table names containing square brackets need to be regex escaped

## v5.2.0

#### Fixed

- [#686](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/686) sql_for_insert set table name in case when pk is not nil

## v5.2.0.rc2

#### Fixed

- [#681](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/681) change_column_null should not clear other column attributes. Fixes #582.
- [#684](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/684) Fix explain with array conditions. Fixes #673.

## v5.2.0.rc1

#### Fixed

- [#638](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/638) Don't disable referential integrity for the same table twice.
- [#646](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/646) Make String equality check work for Type::Data values. Fixes #645.
- [#671](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/671) Fix tinyint columns schema migration. Fixes #670.

#### Changed

- [#642](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/642) Added with (nolock) hint to information_schema.views.


Please check [5-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/5-1-stable/CHANGELOG.md) for previous changes.
