## v8.0.7

#### Fixed

- [#1334](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1334) Enable identity insert on view's base table for fixtures.
- [#1339](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1339) Fix `insert_all`/`upsert_all` for table names containing numbers.

## v8.0.6

#### Fixed

- [#1318](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1318) Reverse order of values when upserting
- [#1321](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1321) Fix SQL statement to calculate `updated_at` when upserting

## v8.0.5

#### Added

- [#1315](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1315) Add support for `insert_all` and `upsert_all`

## v8.0.4

#### Fixed

- [#1308](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1308) Fix retrieval of temporary table's column information.

## v8.0.3

#### Fixed

- [#1306](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1306) Fix affected rows count when lowercase schema reflection enabled

## v8.0.2

#### Fixed

- [#1272](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1272) Fix parsing of raw table name from SQL with extra parentheses

## v8.0.1

#### Fixed

- [#1262](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1262) Fix distinct alias when multiple databases used.

## v8.0.0

#### Changed

- [#1216](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1216) Refactor adapter interface to match abstract adapter.
- [#1225](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1225) Drop support to Ruby 3.1.

#### Fixed

- [#1215](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1215) Fix mismatched foreign key errors.

Please check [7-2-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/7-2-stable/CHANGELOG.md) for previous changes.
