
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

* Revert string_to_binary changes in 457af60e. Fixes #273.


## v3.2.11

* Handle "No such column" when renaming some columns in the migrations. Fixes #237. Thanks @michelgrootjans.
* Update regex for `RecordNotUnique` exception. Fixes #257. Thanks @pbatorre.
* Pass tds_version to TinyTDS. Fixes #233. Thanks @denispeplin.
* Use CONCAT_NULL_YIELDS_NULL for all TinyTDS connections. Fixes #262. Thanks @noel.
* Fix for Azure SQL. Fixed #263. Thanks @eklipse2k8.
* Drop shoulda and use minitest-spec-rails!!!
* Test TinyTDS 0.6.0.
* Fixed the unit tests due to changes in ActiveRecord that removes blank config values.
* Fixed explain tests that were failing due to changes in ExplainSubscriber, cause was regex
* Fixed change_column to update existing table column rows with new default value if there are any NULL values and the column does not accept nulls
* Fixed change_column to drop and add indexes if the colun type is changes
* Fixed string_to_binary and binary_to_string in some cases where the binary data is not UTF-8
* Fixing generating profile report to create output dir if needed, and code change for printing report
* Adding ruby-prof to Gemfile, needed when running profile test cases
* Updating mocha to work with newer ActiveRecord test cases


## v3.2.10

* Remove connection defaults for host/username/password. Since we want to suppoert Windows Authentication and there are just to many possibilities. So we now have to be explicit.
* Remove really old TinyTDS warning.


## v3.2.9

* The #remove_default_constraint uses #execute_procedure now. Fixes #223. Thanks @gicappa and @clintmiller.
* Mimic other adapters quoting for empty strings passed to integer columns. Fixes #164.
* Allow named parameters in stored procedures. Fixes #216. Thanks @sixfeetover.
* Make sure exclude [__rnt] table names form relation reflection. Fixes #219 and #221. Thanks @sphogan.


## v3.2.8

* Include VERSION in gemspec's files.


## v3.2.7

* Find VERSION in base file out of module namespace. Fixes #208
* Better support for explain without sp_execute args. FIxes #207


## v3.2.6

* Unique has_many associations with pagination now work. Fixes #209


## v3.2.5

* Fix a few test from ActiveRecord 3.2.6 upgrade.
* Fix db_name usage bug in #column_definitions [Altonymous]


## v3.2.4

* Fixed schema reflection for identity columns using ODBC. Fixes #193.


## v3.2.3

* Fixed datetime quoting for ActiveSupport::TimeWithZone objects. Fixes #187 and #189.


## v3.2.2

* Fixes all known issues with cross database schema reflection. Fixes #185 [Chris Altman]
* Fix exists? with offset by patching visitor. Fixes #171 and Fixes #167
* Set default text size to 2147483647 for TinyTDS connections. Fixes #181
* Set @config ivar for 3rd party libs. Fixes #177
* Make #sql_type_for_statement work for integers that may have empty parens or none at all. Fixes #175


## v3.2.1

* Add explicit order-by clause for windowed results. Fixes #161.


## v3.2.0

* ActiveRecord explain (SHOWPLAN) support. http://youtu.be/ckb3YYZZZ2Q
* Remove our log_info_schema_queries config since we are not hooking properly into AR's 'SCHEMA' names.
* Properly use 'SCHEMA' name arguement in DB statements to comply with ActiveRecord::ExplainSubscriber::IGNORED_PAYLOADS.
* Make use of the new ConnectionAdapters::SchemaCache for our needs.
* New SQLServer::Utils class for out helpers. Moved table name unquotes there.


## v3.1.5

* Better support for orders with an expression. Fixes #155. [Jason Frey, Joe Rafaniello]


## v3.1.4

* Use INFORMATION_SCHEMA.KEY_COLUMN_USAGE for schema reflection speed. Fixes #125. [Wüthrich Hannes @hwuethrich]
* New deadlock victim retry using the #retry_deadlock_victim config.  [Jason Frey, Joe Rafaniello]
* Renamed #with_auto_reconnect to #with_sqlserver_error_handling now that it handles both dropped connections and deadlock victim errors. Fixes #150 [Jason Frey, Joe Rafaniello]
* Add activity_stats method that mimics the SQL Server Activity Monitor. Fixes #146 [Jason Frey, Joe Rafaniello]
* Add methods for sqlserver's #product_version, #product_level, #edition and include them in inspect. Fixes #145 [Jason Frey, Joe Rafaniello]
* Handle statements that cannot be retried on a new database connection by not reconnecting. Fixes #147 [Jason Frey, Joe Rafaniello]
* Added connection#spid for debugging. Fixes #144 [Jason Frey, Joe Rafaniello]
* Add ENV['TEST_FILES'] to Rakefile for easy single case tests. [Jason Frey, Joe Rafaniello]
* Pass ActiveRecord tests. Made windowed distinct pass all orders to groups.
  - test_limited_eager_with_multiple_order_columns
  - test_limited_eager_with_order
* Pass AR tests by moving DISTINCT to GROUP BY in windowed SQL.
  - test_count_eager_with_has_many_and_limit_and_high_offset
  - test_eager_with_has_many_and_limit_and_high_offset


## v3.1.3

* Distinguish between identity and primary key key columns during schema reflection. Allows us to only do identity inserts when technically needed. Fixes #139 [chadcf] & [joncanady]


## v3.1.2

* Fix SQL Azure conflicts with DBCC useroptions. Use new #user_options_xyz methods. [kazamachi]
* Fix identity inserts for tables with natural PKs. [Gian Carlo Pace]
* Create a #configure_connection method that can be overridden. Think "SET TEXTSIZE...".
* Create a #configure_application_name method that can be overridden for unique TinyTDS app names
* Fixed the #finish_statement_handle to cancel the TinyTDS connection if needed.


## v3.1.1

* Make #rollback_db_transaction smarter.
* Provide a method to override for the quoted string prefix. Not a config because trumping this method will have drastically bad results. Fixes #124
* Allow :limit/:offset to be used with fully qualified table and column in :select.


## v3.1.0

* Add support/test around handling of float/real column types [Lucas Maxwell]
* Make auto reconnect duration configurable. Fixes #109 [David Chelimsky]
* Quote most time objects to use ISO8601 format to be multi-language dateformat compatible. The [datetime] data type is automatically limited to milliseconds while [time] & [datetimeoffset] have full support. Even included a Date/Time ActiveSupport formatter that is used per the language settings of the connection.
* Include a visit_Arel_Nodes_UpdateStatement method in our Arel visitor to add a limit/top for update that has order and no limit/top. https://github.com/rails/rails/commit/787194ee43ab1fb0a7dc8bfbbfbd5079b047d833
* Allow drop_database to be called even when DB does not exist.
* Remove totally broken ADONET connection mode. Want it back, submit a patch.
* Schema reflection now finds primary key for all occasions. Fixed #60 [Boško Ivanišević]
* Allow complex order objects to not be molested by our visitor overrides. Fixes #99
* Default unicode datatypes!
* New #lowercase_schema_reflection configuration that allows you to downcase all tables and columns. Good for legacy databases. Fixes #86. Thanks @dmajkic.
* Rails 3.1 with prepared statement support. Uses "EXEC sp_executesql ..." for just about everything now.


## v3.0.15

* Way better schema support! Thanks to @ianic! Fixes #61
* Warn of possible permission problems if "EXEC sp_helptext..." does not work view. Fixes #73.


## v3.0.13/3.0.14

* Allow TinyTDS/DBLIB mode to pass down :host/:port config options.


## v3.0.12

* Bug fix for previous TinyTDS lost connections.


## v3.0.11

* Azure compatibility.
* TinyTDS enhancements for lost connections. Default connection mode.


## v3.0.10

* Fix #rowtable_orders visitor helper to use first column if no pk column was found.
* Flatten sp_helpconstraint when looking for constraints just in case fks are present. Issue #64.
* Start to support 2011 code named "Denali".
* Limit and Offset can take SqlLiteral objects now.


## v3.0.9

* Fix array literal parsing bug for ruby 1.9.


## v3.0.8

* Support for ActiveRecord v3.0.3 and ARel v2.0.7


## v3.0.7

* Properly quote table names when reflecting on views.
* Add "dead or not enabled" to :dblib's lost connection messages.


## v3.0.6

* Maintenance release. Lock down to ActiveRecord 3.0.1 using ARel 1.0.0.


## v3.0.5

* Fixed native database type memoization, now at connection instance level. Fix #execute_procedure for :dblib mode to return indifferent access rows too.
* Make login timeout and query timeout backward database.yml friendly for :dblib mode.


## v3.0.4

* Add multiple results set support with #execute_procedure for :dblib mode. [Ken Collins]
* Simplify encoding support. [Ken Collins]
* Add binary timestamp datatype handling. [Erik Bryn]


## v3.0.3

* Add TinyTDS/dblib connection mode. [Ken Collins]


## v3.0.2

* Fix DSN'less code. [Erik Bryn]


## v3.0.1

* Support DSN'less connections. Resolves ticket 38.
* Support upcoming ruby odbc 0.99992


## v3.0.0

* Release rails 3 version!


## v2.3.8

* Properly quote all database names in rake helper methods. [Ken Collins]


## v2.3.7

* Correctly use :date/:time SQL types in 2008 [Ken Collins]


## v2.3.6

* Allow DNS's to not contain a database and use what is in database.yml [Marco Mastrodonato]
* Rake tasks methods for vanilla rails :db namespace parity. [Ken Collins]
* IronRuby integrated security fixes [Jimmy Schementi]


## v2.3.5

* Initial IronRuby ADONET connection mode support baked right in. Removed most &blockparameters, no handle/request object yielded anymore. Better abstraction and compliance er the ActiveRecord abstract adapter to not yielding handles for #execute and only forlow level #select. Better wrapping of all queries at lowest level in #log so exceptionsat anytime can be handled correctly by core AR. Critical for System::Data's commandreaders. Better abstraction for introspecting on #connection_mode. Added support forrunning singular test cases via TextMate's Command-R. [Ken Collins]
* Force a binary encoding on values coming in and out of those columns for ruby 1.9.Fixes ticket #33 [Jeroen Zwartepoorte]
* Using change_column will leave default if the type does not change or a new defaultis not included. Fixes issue #22. [Ransom Briggs]
* Use correct SP name for sp_MSforeachtable so any collation can get to it. [7to3]
* Qualify INFORMATION_SCHEMA.COLUMNS with a correct period DB name if present.
* Allow adapter to return multiple results sets, for example from stored procedures. [Chris Hall]


## v2.3.4

* For tables that named with schema(ex. rails.users), they could not get length of column. Column of varchar(40) gets length => nil. Ticket #27 & #15 [Ken Tachiya]
* Altered limited_update_conditions regex conditions, the .* would greedily fail if the where_sql had WHERE in a table or field, etc. [Ransom Briggs]
* Changing test to allow ENV['ARUNIT_DB_NAME'] as the database name for the test units. Matches up with AR conventions. [Ransom Briggs]


## v2.3.3

* Revert #ad83df82 and again cache column information at the connection's instance. The previous commit was causing all sorts of view and schema reflection problems. [Ken Collins]


## v2.3.2

* Insert queries that include the word "insert" as a partial column name with the word "id" as a value were falsely being matched as identity inserts. [Sean Caffery/bfabry]
* Delegate all low level #raw_connection calls to #raw_connection_run and #raw_connection_do which abstract out the low level modes in the connection options at that point. [Ken Collins]
* Remove DBI dependency and go straight ODBC for speed improvement [Erik Bryn]
* Leave order by alone when same column crosses two tables [Ransom Briggs]


## v2.3.0 (2009-12-01)

* Table and column aliases can handle many. Resolves ticket #19 [stonegao]
* Coerce a few tests that were failing in 2.3.x [Ken Collins]
* Change column/view cache to happen at class level. Allows connection pool to share same caches as well as the ability to expire the caches when needed. Also fix change_column so that exceptions are not raised when the column contains an existing default. [Ken Collins]
* Allow query_requires_identity_insert? method to return quoted table name in situations where the INSERT parts are not quoted themselves. [Gary/iawgens, Richard Penwell, Ken Collins]
* Fixed namespace in calling test_sqlserver_odbc within test_unicode_types. [Gary/iawgens]
* Columns with multi-line defaults work correctly. [bfabry]


## v2.2.22 (2009-10-15)

* Support Identity-key-column judgement on multiple schema environment [Ken Tachiya]
* Add support for tinyint data types. In MySQL all these types would be boolean, however in our adapter, they will use the full 1 => 255 Fixnum value as you would expect. [Ken Collins]


## v2.2.21 (2009-09-10)

* Changes for gem best practices per http://weblog.rubyonrails.org/2009/9/1/gem-packaging-best-practices. Details of such are as follows: [Ken Collins]
  - Removed rails-sqlserver-2000-2005-adapter.rb load file for old github usage.
  - Move the core_ext directory to active_record/connection_adapters/sqlserver_adapter/core_ext
  - Renamespace SQLServerDBI to ActiveRecord::ConnectionAdapters::SQLServerCoreExtensions::DBI
  - Renamespace ActiveRecord::ConnectionAdapters::SQLServerActiveRecordExtensions to ActiveRecord::ConnectionAdapters::SQLServerCoreExtensions::ActiveRecord


## v2.2.20 (2009-09-10)

* Implement a new remove_default_constraint method that uses sp_helpconstraint [Ken Collins]
* Use a lazy match in add_order_by_for_association_limiting! to allow sub selects to be used. Resolves ticket #11.
* Add default rake task back for testing. Runs the namespaced sqlserver:test_sqlserver_odbc. Resolves ticket #10 [Ken Collins]
* Default value detection in column_definitions is kinder to badly formatted, or long winded user defined functions, for default values. Resolves ticket #8 [Ken Collins]
* Make sure bigint SQL Server data type can be used and converted back to Bignum as expected. [Ken Collins]


## v2.2.19 (2009-06-19)

* Leave quoted column names as is. Resolves ticket #36 [Vince Puzzella]
* Changing add_limit! in ActiveRecord::Base for SQLServer so that it passes through any scoped :order parameters. Resolves ticket #35 [Murray Steele]


## v2.2.18 (2009-06-05)

* Column reflection on table name rescues LoadError and a few others. Resolves tickets #25 & #33 [Ken Collins]
* Added 2008 support. Resolves ticket #32 [Ken Collins]


## v2.2.17 (2009-05-14)

* Add simplified type recognition for varchar(max) and nvarchar(max) under SQL Server 2005 to be a :text type. This ensures schema dumper does the right thing. Fixes ticket #30. [Ken Collins]
* Tested ruby 1.9, ruby-odbc 0.9996, and DBI 0.4.1. Also added correct support for UTF-8 character encoding going in and out of the DB. See before gist http://gist.github.com/111709 and after gist http://gist.github.com/111719 [Ken Collins]


## v2.2.16 (2009-04-21)

* Make add_limit_offset! only add locking hints (for tally) when the :lock option is present. Added tests to make sure tally SQL is augmented correctly and tests to make sure that add_lock! is doing what it needs for deep sub selects in paginated results. [Ken Collins]
* Add auto reconnect support utilizing a new #with_auto_reconnect block. By default each query run through the adapter will automatically reconnect at standard intervals, logging attempts along the way, till success or the original exception bubbles up. See docs for more details. Resolves ticket #18 [Ken Collins]
* Update internal helper method #orders_and_dirs_set to cope with an order clause like "description desc". This resolves ticket #26 [Ken Collins]
* Provide support for running queries at different isolation levels using #run_with_isolation_level method that can take a block or not. Also implement a #user_options method that reflects on the current user session values. Resolves #20 [Murray Steele]


## v2.2.15 (2009-03-23)

* Better add_lock! method that can add the lock to just about all the elements in the statement. This could be eager loaded associations, joins, etc. Done so that paginated results can easily add lock options for performance. Note, the tally count in add_limit_offset! use "WITH (NOLOCK)" explicitly as it can not hurt and is needed. [Ken Collins]


## v2.2.14 (2009-03-17)

* Back passing tests on 2.2 work. Includes: (1) Created new test helpers that check ActiveRecordversion strings so we can conditionally run 2.2 and 2.3 tests. (2) Making TransactionTestSQLServer use Ship vsBird model. Also made it conditional run a few blocks for different versions of ActiveRecord. (3) PreviousJoinDependency#aliased_table_name_for is now only patched in ActiveRecord equal or greater than 2.3. [Ken Collins]
* Implement new savepoint support [Ken Collins]http://rails.lighthouseapp.com/projects/8994/tickets/383http://www.codeproject.com/KB/database/sqlservertransactions.aspx
* Coerce NestedScopingTest#test_merged_scoped_find to use correct regexp for adapter. [Ken Collins]
* Implement a custom ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation#aliased_table_name_formethod that uses a Regexp.escape so that table/column quoting does not get ignored. [Ken Collins]
* Implement #outside_transaction? and a new transaction test case to test some SQL Serverbasic support while implementing this method. Future home of some savepoint tests too. [Ken Collins]
* Rails2.3 - Coerced tests that ensure hash conditions on referenced tables are considered when eagerloading with limit/offset. Information on these changes and the ticket in rails are.http://github.com/rails/rails/commit/9a4d557713acb0fc8e80f61af18094034aca029ahttp://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/1404-conditions_tables-doesnt-understand-condition-hashes
* Add coerced tests for true/false attributes in selects use SQL Server case statement. [Ken Collins]
* Making sure that smalldatetime types are OK to use. Also fixed a bug in the #view_information method thatchecks to see if a view definition is equal to 4000 chars, meaning that it is most likely truncated andneeds to use the backup method of sp_helptext to get it's view definition. [Ken Collins]


## v2.2.13 (2009-02-10)

* Update #indexes to use unqualified table name. Fixes cases where users may decide to use tablename prefixes like 'dbo.'. [Ken Collins]


## v2.2.12 (2009-02-08)

* Update table_exists? to work with qualified table names that may include an user prefix. [Ken Collins]


## v2.2.10/11 (2009-01-22)

* Add a rails-sqlserver-2000-2005-adapter.rb file so that long :lib option for config.gem is no longer needed.


## v2.2.9 (2009-01-22)

* Fixing a small bug in the deprecated DBI::Timestamp conversion so it correctly converts nanosecond wholenumbers to back to pre type cast SQL Server milliseconds, ultimately allow ruby's Time#usec which ismicroseconds to be correct. [Ken Collins]
* Sometimes views are more than 4000 chars long and will return NULL for the VIEW_DEFINITION. If so, usesp_helptext procedure as a backup method. [Ken Collins]


## v2.2.8 (2009-01-09)

* Update execute_procedure method a bit to remove excess code. [Ken Collins]


## v2.2.7 (2009-01-09)

* Created a connection#execute_procedure method that takes can take any number of ruby objects as variablesand quotes them according to the connection's rules. Also added an ActiveRecord::Base class level coreextension that hooks into this. It also checks if the connection responds to #execute_procedure and ifnot returns an empty array. [Ken Collins]
* Added a #enable_default_unicode_types class attribute access to make all new added or changed string typeslike :string/:text default to unicode/national data types. See the README for full details. Added a raketask that assists setting this to true when running tests.  [Ken Collins]


## v2.2.6 (2009-01-08)

* Introduced a bug in 2.2.5 in the #add_order! core ext for ActiveRecord. Fixed [Ken Collins]


## v2.2.5 (2009-01-04)

* Added a log_info_schema_queries class attribute and make all queries to INFORMATION_SCHEMA silent bydefault. [Ken Collins]
* Fix millisecond support in datetime columns. ODBC::Timestamp incorrectly takes SQL Server millisecondsand applies them as nanoseconds. We cope with this at the DBI layer by using SQLServerDBI::Type::SQLServerTimestampclass to parse the before type cast value appropriately. Also update the adapters #quoted_date methodto work more simply by converting ruby's #usec milliseconds to SQL Server microseconds. [Ken Collins]
* Core extensions for ActiveRecord now reflect on the connection before doing SQL Server things. Nowthis adapter is compatible for using with other adapters. [Ken Collins]


## v2.2.4 (2008-12-05)

* Fix a type left in #views_real_column_name. Also cache #view_information lookups. [Ken Collins]


## v2.2.3 (2008-12-05)

* Changing back to using real table name in column_definitions. Makes sure views get back only the columnsthat are defined for them with correct names, etc. Now supporting views by looking for NULL default andthen if table name is a view, perform a targeted with sub select to the real table name and column nameto find true default. [Ken Collins]
* Ensure that add_limit_offset! does not alter sub queries. [Erik Bryn]


## v2.2.2 (2008-12-02)

* Add support for view defaults by making column_definitions use real table name for schema info. [Ken Collins]
* Include version in connection method and inspection. [Ken Collins]


## v2.2.1 (2008-11-25)

* Add identity insert support for views. Cache #views so that identity #table_name_or_views_table_namewill run quickly. [Ken Collins]
* Add views support. ActiveRecord classes can use views. The connection now has a #views method and #table_exists? will now fall back to checking views too. [Ken Collins]


## v2.2.0 (2008-11-21)

* Release for rails 2.2.2. Many many changes.  [Ken Collins], [Murray Steele], [Shawn Balestracci], [Joe Rafaniello]

