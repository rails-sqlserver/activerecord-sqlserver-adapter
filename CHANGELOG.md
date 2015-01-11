
## v4.2.0

#### Added

* New `ActiveRecord::Type` objects. See `active_record/connection_adapters/sqlserver/type` dir.
* New `SQLServer::Utils::Name` object for decomposing and quoting SQL Server names/identifiers.

#### Changed

* Complete rewrite of our Arel visitor. Focuing on 2012 and upward so we can make FETCH happen.
* Testing enhancements.
  * Guard support, check our Guardfile.
  * Use `ARTest` namespace with `SQLServer` module for our helpers/objects.
  * Simple 2012 schmea addition and extensive column/type_cast object tests.

#### Deprecated

* n/a

#### Removed

* SQL Server versions < 2012 which do not support OFFSET and FETCH. http://bit.ly/1B5Bwsd
* The `enable_default_unicode_types` option. Default to national types all the time. Use SQL type name in migrations if needed.
* Native type configs for older DB support. Includes the following with new default value.
  * native_string_database_type => `nvarchar`
  * native_text_database_type   => `nvarchar(max)`
  * native_binary_database_type => `varbinary(max)`


#### Fixed

* n/a

#### Security

* n/a


