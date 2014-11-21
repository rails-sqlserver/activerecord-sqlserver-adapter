# ActiveRecord SQL Server Adapter. For SQL Server 2005 And Higher.

**This project is looking for a new maintainers. Join the [discusion here](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/364)**

The SQL Server adapter for ActiveRecord. If you need the adapter for SQL Server 2000, you are still in the right spot. Just install the latest 2.3.x version of the adapter. Note, we follow a rational versioning policy that tracks ActiveRecord. That means that our 2.3.x version of the adapter is only for the latest 2.3 version of Rails. We also have stable branches for each major/minor release of ActiveRecord.


## What's New

* Rails 4.0 and 4.1 support
* Ruby 2.0 and 2.1 support


#### Testing Rake Tasks Support

This is a long story, but if you are not working with a legacy database and you can trust your schema.rb to setup your local development or test database, then we have adapter level support for rails :db rake tasks. Please read this wiki page for full details.

http://wiki.github.com/rails-sqlserver/activerecord-sqlserver-adapter/rails-db-rake-tasks


#### Date/Time Data Type Hinting

SQL Server 2005 does not include a native data type for just `date` or `time`, it only has `datetime`. To pass the ActiveRecord tests we implemented two simple class methods that can teach your models to coerce column information to be cast correctly. Simply pass a list of symbols to either the `coerce_sqlserver_date` or `coerce_sqlserver_time` methods that correspond to 'datetime' columns that need to be cast correctly.

```ruby
class Topic < ActiveRecord::Base
  coerce_sqlserver_date :last_read
  coerce_sqlserver_time :bonus_time
end
```

This implementation has some limitations. To date we can only coerce date/time types for models that conform to the expected ActiveRecord class to table naming conventions. So a table of 'foo_bar_widgets' will look for coerced column types in the FooBarWidget class.


#### Executing Stored Procedures

Every class that sub classes ActiveRecord::Base will now have an execute_procedure class method to use. This method takes the name of the stored procedure which can be a string or symbol and any number of variables to pass to the procedure. Arguments will automatically be quoted per the connection's standards as normal. For example:

```ruby
Account.execute_procedure :update_totals, 'admin', nil, true
# Or with named parameters.
Account.execute_procedure :update_totals, named: 'params'
```

#### Native Data Type Support

Currently the following custom data types have been tested for schema definitions.

* char
* nchar
* nvarchar
* ntext
* varchar(max)
* nvarchar(max)

For example:

```ruby
create_table :sql_server_custom_types, force: true do |t|
  t.column :ten_code,       :char,      limit: 10
  t.column :ten_code_utf8,  :nchar,     limit: 10
  t.column :title_utf8,     :nvarchar
  t.column :body,           :varchar_max    # Creates varchar(max)
  t.column :body_utf8,      :ntext
  t.column :body2_utf8,     :nvarchar_max   # Creates nvarchar(max)
end
```

Manually creating a `varchar(max)` is not necessary since this is the default type created when specifying a `:text` field. As time goes on we will be testing other SQL Server specific data types are handled correctly when created in a migration.


#### Native Text/String/Binary Data Type Accessor

To pass the ActiveRecord tests we had to implement an class accessor for the native type created for `:text` columns. By default any `:text` column created by migrations will create a `varchar(max)` data type. This type can be queried using the SQL = operator and has plenty of storage space which is why we made it the default. If for some reason you want to change the data type created during migrations you can configure this line to your liking in a config/initializers file.

```ruby
ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_text_database_type = 'varchar(8000)'
```

Also, there is a class attribute setter for the native string database type. This is the same for all SQL Server versions, `varchar`. However it can be used instead of the #enable_default_unicode_types below for finer grain control over which types you want unicode safe when adding or changing the schema.

```ruby
ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_string_database_type = 'nvarchar'
```

By default any :binary column created by migrations will create a `varbinary(max)` data type. This too can be set using an initializer.

```ruby
ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_binary_database_type = 'image'
```

####  Setting Unicode Types As Default

By default the adapter will use unicode safe data types for `:string` and `:text` types when defining/changing the schema! This was changed in version 3.1 since it is about time we push better unicode support and since we default to TinyTDS (DBLIB) which supports unicode queries and data. If you choose, you can set the following class attribute in a config/initializers file that will disable this behavior.

```ruby
# Default
ActiveRecord::ConnectionAdapters::SQLServerAdapter.enable_default_unicode_types = true
ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_text_database_type = 'nvarchar(max)'
ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_string_database_type = 'nvarchar'

# Disabled
ActiveRecord::ConnectionAdapters::SQLServerAdapter.enable_default_unicode_types = false
ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_text_database_type = 'varchar(max)'
ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_string_database_type = 'varchar'
```

It is important to remember that unicode types in SQL Server have approximately half the storage capacity as their counter parts. So where a normal string would max out at (8000) a unicode string will top off at (4000).


#### Force Schema To Lowercase

Although it is not necessary, the Ruby convention is to use lowercase method names. If your database schema is in upper or mixed case, we can force all table and column names during the schema reflection process to be lowercase. Add this to your config/initializers file for the adapter.

```ruby
ActiveRecord::ConnectionAdapters::SQLServerAdapter.lowercase_schema_reflection = true
```


#### Schemas & Users

Depending on your user and schema setup, it may be needed to use a table name prefix of `dbo.`. So something like this in your initializer file for ActiveRecord or the adapter.

```ruby
ActiveRecord::Base.table_name_prefix = 'dbo.'
```


#### Auto Connecting

By default the adapter will auto connect to lost DB connections. For every query it will retry at intervals of 2, 4, 8, 16 and 32 seconds. During each retry it will callback out to ActiveRecord::Base.did_retry_sqlserver_connection(connection,count). When all retries fail, it will callback to ActiveRecord::Base.did_lose_sqlserver_connection(connection). Both implementations of these methods are to write to the rails logger, however, they make great override points for notifications like Hoptoad. If you want to disable automatic reconnections use the following in an initializer.

```ruby
ActiveRecord::ConnectionAdapters::SQLServerAdapter.auto_connect = false
```


#### Configure Connection & App Name

We currently conform to an unpublished and non-standard AbstractAdapter interface to configure connections made to the database. To do so, just override the `configure_connection` method in an initializer like so. In this case below we are setting the `TEXTSIZE` to 64 megabytes. Also, TinyTDS supports an application name when it logs into SQL Server. This can be used to identify the connection in SQL Server's activity monitor. By default it will use the `appname` from your database.yml file or a lowercased version of your Rails::Application name. It is now possible to define a `configure_application_name` method that can give you per instance details. Below shows how you might use this to get the process id and thread id of the current connection.

```ruby
module ActiveRecord
  module ConnectionAdapters
    class SQLServerAdapter < AbstractAdapter

      def configure_connection
        raw_connection_do "SET TEXTSIZE #{64.megabytes}"
      end

      def configure_application_name
        "myapp_#{$$}_#{Thread.current.object_id}".to(29)
      end

    end
  end
end
```

#### Explain Support (SHOWPLAN)

The 3.2 version of the adapter support ActiveRecord's explain features. In SQL Server, this is called the showplan. By default we use the `SHOWPLAN_ALL` option and format it using a simple table printer. So the following ruby would log the plan table below it.

```ruby
Car.where(id: 1).explain
```

```
EXPLAIN for: SELECT [cars].* FROM [cars] WHERE [cars].[id] = 1
+----------------------------------------------------+--------+--------+--------+----------------------+----------------------+----------------------------------------------------+----------------------------------------------------+--------------+---------------------+----------------------+------------+---------------------+----------------------------------------------------+----------+----------+----------+--------------------+
| StmtText                                           | StmtId | NodeId | Parent | PhysicalOp           | LogicalOp            | Argument                                           | DefinedValues                                      | EstimateRows | EstimateIO          | EstimateCPU          | AvgRowSize | TotalSubtreeCost    | OutputList                                         | Warnings | Type     | Parallel | EstimateExecutions |
+----------------------------------------------------+--------+--------+--------+----------------------+----------------------+----------------------------------------------------+----------------------------------------------------+--------------+---------------------+----------------------+------------+---------------------+----------------------------------------------------+----------+----------+----------+--------------------+
| SELECT [cars].* FROM [cars] WHERE [cars].[id] = 1  |      1 |      1 |      0 | NULL                 | NULL                 | 2                                                  | NULL                                               |          1.0 | NULL                | NULL                 | NULL       | 0.00328309996984899 | NULL                                               | NULL     | SELECT   | false    | NULL               |
|   |--Clustered Index Seek(OBJECT:([activerecord... |      1 |      2 |      1 | Clustered Index Seek | Clustered Index Seek | OBJECT:([activerecord_unittest].[dbo].[cars].[P... | [activerecord_unittest].[dbo].[cars].[id], [act... |          1.0 | 0.00312500004656613 | 0.000158099996042438 |        278 | 0.00328309996984899 | [activerecord_unittest].[dbo].[cars].[id], [act... | NULL     | PLAN_ROW | false    |                1.0 |
+----------------------------------------------------+--------+--------+--------+----------------------+----------------------+----------------------------------------------------+----------------------------------------------------+--------------+---------------------+----------------------+------------+---------------------+----------------------------------------------------+----------+----------+----------+--------------------+
```

You can configure a few options to your needs. First is the max column width for the logged table. The default value is 50 characters. You can change it like so.

```ruby
ActiveRecord::ConnectionAdapters::Sqlserver::Showplan::PrinterTable.max_column_width = 500
```

Another configuration is the showplan option. Some might find the XML format more useful. If you have Nokogiri installed, we will format the XML string. I will gladly accept pathches that make the XML printer more useful!

```ruby
ActiveRecord::ConnectionAdapters::SQLServerAdapter.showplan_option = 'SHOWPLAN_XML'
```
**NOTE:** The method we utilize to make SHOWPLANs work is very brittle to complex SQL. There is no getting around this as we have to deconstruct an already prepared statement for the sp_executesql method. If you find that explain breaks your app, simple disable it. Do not open a github issue unless you have a patch.  Please [consult the Rails guides](http://guides.rubyonrails.org/active_record_querying.html#running-explain) for more info.

## Versions

The adapter follows a rational versioning policy that also tracks ActiveRecord's major and minor version. That means the latest 3.1.x version of the adapter will always work for the latest 3.1.x version of ActiveRecord.


## Installation

The adapter has no strict gem dependencies outside of ActiveRecord. You will have to pick a connection mode, the default is dblib which uses the TinyTDS gem. Just bundle the gem and the adapter will use it.

```ruby
gem 'tiny_tds'
gem 'activerecord-sqlserver-adapter', '~> 4.0.0'
```

If you want to use ruby ODBC, please use at least version 0.99992 since that contains fixes for both native types as well as fixes for proper encoding support under 1.9. If you have any troubles installing the lower level libraries for the adapter, please consult the wiki pages for various platform installation guides. Tons of good info can be found and we ask that you contribute too!

http://wiki.github.com/rails-sqlserver/activerecord-sqlserver-adapter/platform-installation



## Contributing

If you would like to contribute a feature or bugfix, thanks! To make sure your fix/feature has a high chance of being added, please read the following guidelines. First, ask on the Google list, IRC, or post a ticket on github issues. Second, make sure there are tests! We will not accept any patch that is not tested. Please read the `RUNNING_UNIT_TESTS` file for the details of how to run the unit tests.

* Github: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter
* Google Group: http://groups.google.com/group/rails-sqlserver-adapter
* IRC Room: #rails-sqlserver on irc.freenode.net


## Credits & Contributions

Many many people have contributed. If you do not see your name here and it should be let us know. Also, many thanks go out to those that have pledged financial contributions.


## Contributers
Up-to-date list of contributors: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter/contributors

* metaskills (Ken Collins)
* Annaswims (Annaswims)
* Thirdshift (Garrett Hart)
* h-lame (Murray Steele)
* vegantech
* cjheath (Clifford Heath)
* fryguy (Jason Frey)
* jrafanie (Joe Rafaniello)
* nerdrew (Andrew Ryan)
* snowblink (Jonathan Lim)
* koppen (Jakob Skjerning)
* ebryn (Erik Bryn)
* adzap (Adam Meehan)
* neomindryan (Ryan Findley)
* jeremydurham (Jeremy Durham)


## License

Copyright © 2008-2014. It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.

