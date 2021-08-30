#### Unreleased

#### Fixed

- [#940](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/940) Primary key violation should result in RecordNotUnique error

#### Changed

- ...

#### Added

- ...

## v6.1.1.0

[Full changelog](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/compare/v6.1.0.0...v6.1.1.0)

#### Fixed

- [#933](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/933) Conditionally apply SQL Server monkey patches to ActiveRecord so that it is safe to use this gem alongside other database adapters (e.g. PostgreSQL) in a multi-database Rails app
- [#935](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/935) Fix schema cache generation
  (**breaking change**)
- [#936](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/936) Fix deteministic fetch when table has a composite primary key
- [#938](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/938) Fix date columns serialization for range values

## v6.1.0.0

- No changes

## v6.1.0.0.rc1

[Full changelog](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/compare/6-0-stable...v6.1.0.0.rc1)

#### Fixed

- [#872](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/872) Use native String#start_with
- [#876](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/876) Use native String#end_with
- [#873](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/873) Various fixes to get the tests running for Rails 6.1
- [#874](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/874) Deduplicate schema cache structures
- [#875](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/875) Handle default boolean column values when deduplicating
- [#879](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/879) Added visit method for HomogeneousIn
- [#880](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/880) Handle any default column class when deduplicating
- [#861](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/861) Fix Rails 6.1 database config
- [#890](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/890) Fix removal of invalid ordering from select statements
- [#881](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/881) Dump column collation to schema.rb and allow collation changes using column_change
- [#891](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/891) Add support for if_not_exists to indexes
- [#892](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/892) Add support for if_exists on remove_column
- [#883](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/885) Fix quoting of ActiveRecord::Relation::QueryAttribute and ActiveModel::Attributes
- [#893](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/893) Add Active Record Marshal forward compatibility tests
- [#903](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/903) Raise ActiveRecord::ConnectionNotEstablished on calls to execute with a disconnected connection

#### Changed

- [#917](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/917) Refactored to use new_client connection pattern

Please check [6-0-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/6-0-stable/CHANGELOG.md) for previous changes.
