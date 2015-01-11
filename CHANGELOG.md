
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


## v4.1.0

* Not sure if this even happened. Just got to 4.2.0 :)


## v4.0.0

* Dropped support for ruby 1.8.7
* Removed deadlock victim retry in favor of Isolation Level
* Removed auto_explain_threshold_in_seconds (not used in rails 4)


## v3.2.12




