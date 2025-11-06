## Unreleased

#### Fixed

- [#1371](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1371) Fixed query logging so that filter parameters are respected.

## v7.2.8

#### Fixed

- [#1365](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1365) Verify connection before retrieving the database version.

## v7.2.7

#### Changed

- [#1341](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1341) Support more Azure services by changing language source.

#### Fixed

- [#1357](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1357) Support cross database inserts.

## v7.2.6

#### Fixed

- [#1333](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1333) Enable identity insert on view's base table for fixtures.

## v7.2.5

#### Fixed

- [#1308](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1308) Fix retrieval of temporary table's column information.

## v7.2.4

#### Fixed

- [#1270](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1270) Fix parsing of raw table name from SQL with extra parentheses

## v7.2.3

#### Fixed

- [#1262](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1262) Fix distinct alias when multiple databases used.

## v7.2.2

#### Fixed

- [#1244](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1244) Allow INSERT statements with SELECT notation
- [#1247](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1247) Fix queries with date and date-time placeholder conditions
- [#1249](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1249) Binary basic columns should be limitable
- [#1255](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1255) Fixed the ordering of optimizer hints in the generated SQL

## v7.2.1

#### Fixed

- [#1231](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1231) Enable identity insert on view's base table

## v7.2.0

#### Added

- [#1178](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1178) Support encrypting binary columns

#### Changed

- [#1153](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1153) Only support Ruby v3.1+
- [#1196](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1196) Use default inspect for database adapter


Please check [7-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/7-1-stable/CHANGELOG.md) for previous changes.
