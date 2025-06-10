## Unreleased

#### Added

- [#1301](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1301) Add support for `INDEX INCLUDE`.
- [#1312](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1312) Add support for `insert_all` and `upsert_all`.
- [#1317](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1317) Reverse order of values when upserting.

#### Changed

- [#1273](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1273) TinyTDS v3+ is now required.

#### Fixed

- [#1313](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1313) Correctly retrieve the SQL Server database version.
- [#1320](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1320) Fix SQL statement to calculate `updated_at` when upserting.
- [#1327](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1327) Fix multiple `nil` identity columns for merge insert.
- [#1338](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1338) Fix `insert_all`/`upsert_all` for table names containing numbers.

Please check [8-0-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/8-0-stable/CHANGELOG.md) for previous changes.
