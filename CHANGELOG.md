## v5.0.6

#### Fixed

* Performance w/inserts. Check binds & use schema cache for id inserts.
  Fixes #572. Thanks @noelr.

#### Changed

* Misc index enhancements or testing. Fixes #570
  Enable `supports_index_sort_order?`, test `supports_partial_index?`, test how expression indexes work.

#### Added

* New `primary_key_nonclustered` type for easy In-Memory table creation.
* Examples for an In-Memory table.

```ruby
create_table :in_memory_table, id: false,
             options: 'WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)' do |t|
  t.primary_key_nonclustered :id
  t.string :name
  t.timestamps
end
```


## v5.0.5

#### Changed

* Add TinyTDS as a runtime dependency.


## v5.0.4

#### Fixed

* Allow `datetimeoffset` to be used in migrations and represented in schema.
* Using transactions and resetting isolation level correctly when `READ_COMMITTED_SNAPSHOT` is set to `ON` Fixes #520


## v5.0.3

#### Changed

* Reduce view information reflection to per table vs. column. Fixes #552
* The `user_options` parsing. Works for hash/array. Fixes #535
* Pass the `:contained` option to TinyTDS. Fixes #527


## v5.0.2

#### Fixed

* Filter table constraints with matching table schema to column. Fixes #478


## v5.0.1

#### Changed

* Set `tds_version` fallback to `7.3`.

#### Fixed

* Support 2014, 2012 drop table statement.


## v5.0.0

#### Added

* Support for `supports_datetime_with_precision`.
* Support for `unprepared_statement` blocks on the connection.

#### Changed

* Major refactoring of all type objects. Especially time types.

#### Deprecated

* Support for a handful of standard Rails deprecations in 5-0-stable suite.

#### Removed

* ODBC connection mode. Not been maintained since Rails 4.0.
* View table name detection in `with_identity_insert_enabled` method for fixtures. Perf hit.

#### Fixed

* Do not output column collation in schema when same as database.
