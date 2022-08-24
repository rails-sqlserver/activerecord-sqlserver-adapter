## Unreleased

- [#1021](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1021) Freeze the SQL sent to instrumentation.

## v7.0.0.0

[Full changelog](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/compare/v7.0.0.0.rc1...v7.0.0.0)

#### Fixed

- [#1002](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1002) Fix support for index types

#### Changed

- [#1004](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1004) Dump the precision for datetime columns following the new defaults.

## v7.0.0.0.rc1

[Full changelog](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/compare/6-1-stable...v7.0.0.0.rc1)

#### Changed

- [#968](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/968) Define adapter type maps statically
- [#983](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/983) Optimize remove_columns to use a single SQL statement
- [#984](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/984) Better handle SQL queries with invalid encoding
- [#988](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/988) Raise `ActiveRecord::StatementInvalid` when `columns` is called with a non-existing table (***breaking change***)

#### Added

- [#972](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/972) Support `ActiveRecord::QueryLogs`
- [#981](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/981) Support `find_by` an encrypted attribute
- [#985](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/985) Support string returning clause for `ActiveRecord#insert_all`

Please check [6-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/6-1-stable/CHANGELOG.md) for previous changes.
