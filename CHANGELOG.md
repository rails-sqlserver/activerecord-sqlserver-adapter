## v7.0.3.0

#### Fixed

- [#1052](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1052) Ignore casing of VALUES clause when inserting records using SQL
- [#1053](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1053) Fix insertion of records to non-default schema table using raw SQL
- [#1059](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1059) Fix enums defined on string columns

#### Changed

- [#1057](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1057) Set precision 6 by default for timestamps.

## v7.0.2.0

[Full changelog](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/compare/v7.0.1.0...v7.0.2.0)

#### Fixed

- [#1049](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1049) Fix for inserting records into non-dbo schema table.

## v7.0.1.0

[Full changelog](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/compare/v7.0.0.0...v7.0.1.0)

#### Fixed

- [#1029](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1029) Handle views defined in other databases.
- [#1033](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1033) Support proc default values in ruby 3.2.
- [#1020](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1020) Support using adapter as a stand-alone gem.
- [#1039](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1039) Fix hook method that allows custom connection configuration.

#### Changed

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
