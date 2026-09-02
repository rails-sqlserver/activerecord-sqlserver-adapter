## Unreleased

#### Added

- [#1385](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1385) Added support for Nulls first and last.

#### Changed

- [#1381](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1381) Fix `change_column` to preserve old column attributes.
- [#1393](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1393) Treat TinyTDS `failed dbsqlsend() function` errors as `ConnectionNotEstablished` so they're retried instead of surfaced as `StatementInvalid`.
- [#1397](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1397) Treat "DBPROCESS is dead or not enabled" as ConnectionNotEstablished.
- [#1403](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1403) Fix `insert_all`/`upsert_all` for single character, temporary, non-ASCII and three part table names, and stop an aliased target being included in the `MERGE` table name.

Please check [8-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/8-1-stable/CHANGELOG.md) for previous changes.
