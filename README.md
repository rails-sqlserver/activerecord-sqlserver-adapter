
# ActiveRecord SQL Server Adapter. For SQL Server 2012 And Higher.

[![Build status](https://ci.appveyor.com/api/projects/status/mtgbx8f57vr7k2qa/branch/master?svg=true)](https://ci.appveyor.com/project/rails-sqlserver/activerecord-sqlserver-adapter/branch/master) [![Gem Version](http://img.shields.io/gem/v/activerecord-sqlserver-adapter.svg?style=flat)](https://rubygems.org/gems/activerecord-sqlserver-adapter) [![Gitter chat](https://img.shields.io/badge/%E2%8A%AA%20GITTER%20-JOIN%20CHAT%20%E2%86%92-brightgreen.svg?style=flat)](https://gitter.im/rails-sqlserver/activerecord-sqlserver-adapter)

![kantishna-wide](https://cloud.githubusercontent.com/assets/2381/5895051/aa6a57e0-a4e1-11e4-95b9-23627af5876a.jpg)

## Code Name Kantishna

The SQL Server adapter for ActiveRecord v4.2 using SQL Server 2012 or higher.

Interested in older versions? We follow a rational versioning policy that tracks Rails. That means that our 4.2.x version of the adapter is only for the latest 4.2 version of Rails. If you need the adapter for SQL Server 2008 or 2005, you are still in the right spot. Just install the latest 3.2.x to 4.1.x version of the adapter that matches your Rails version. We also have stable branches for each major/minor release of ActiveRecord.


#### Executing Stored Procedures

Every class that sub classes ActiveRecord::Base will now have an execute_procedure class method to use. This method takes the name of the stored procedure which can be a string or symbol and any number of variables to pass to the procedure. Arguments will automatically be quoted per the connection's standards as normal. For example:

```ruby
Account.execute_procedure :update_totals, 'admin', nil, true
# Or with named parameters.
Account.execute_procedure :update_totals, named: 'params'
```


#### Native Data Type Support

We support every data type supported by FreeTDS and then a few more. All simplified Rails types in migrations will coorespond to a matching SQL Server national (unicode) data type. Here is a basic chart. Always check the `initialize_native_database_types` method for an updated list.

```ruby
integer:        { name: 'int', limit: 4 }
bigint:         { name: 'bigint' }
boolean:        { name: 'bit' }
decimal:        { name: 'decimal' }
money:          { name: 'money' }
smallmoney:     { name: 'smallmoney' }
float:          { name: 'float' }
real:           { name: 'real' }
date:           { name: 'date' }
datetime:       { name: 'datetime' }
datetime2:      { name: 'datetime2', precision: 7 }
datetimeoffset: { name: 'datetimeoffset', precision: 7 }
smalldatetime:  { name: 'smalldatetime' }
timestamp:      { name: 'datetime' }
time:           { name: 'time' }
char:           { name: 'char' }
varchar:        { name: 'varchar', limit: 8000 }
varchar_max:    { name: 'varchar(max)' }
text_basic:     { name: 'text' }
nchar:          { name: 'nchar' }
string:         { name: 'nvarchar', limit: 4000 }
text:           { name: 'nvarchar(max)' }
ntext:          { name: 'ntext' }
binary_basic:   { name: 'binary' }
varbinary:      { name: 'varbinary', limit: 8000 }
binary:         { name: 'varbinary(max)' }
uuid:           { name: 'uniqueidentifier' }
ss_timestamp:   { name: 'timestamp' }
```

The following types require TDS version 7.3 with TinyTDS. This requires the latest FreeTDS v0.95 or higher.

* date
* datetime2
* datetimeoffset
* time

Set `tds_version` in your database.yml or the `TDSVER` environment variable to `7.3` to ensure you are using the proper protocol version till 7.3 becomes the default.

**Zone Conversion** - The `[datetimeoffset]` type is the only ActiveRecord time based datatype that does not cast the zone to ActiveRecord's default - typically UTC. As intended, this datatype is meant to maintain the zone you pass to it and/or retreived from the database.


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
ActiveRecord::ConnectionAdapters::SQLServer::Showplan::PrinterTable.max_column_width = 500
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
gem 'activerecord-sqlserver-adapter', '~> 4.2.0'
```

If you want to use ruby ODBC, please use the latest least. If you have any troubles installing the lower level libraries for the adapter, please consult the wiki pages for various platform installation guides. Tons of good info can be found and we ask that you contribute too!

http://wiki.github.com/rails-sqlserver/activerecord-sqlserver-adapter/platform-installation


## Contributing

If you would like to contribute a feature or bugfix, thanks! To make sure your fix/feature has a high chance of being added, please read the following guidelines. First, ask on the Gitter, or post a ticket on github issues. Second, make sure there are tests! We will not accept any patch that is not tested. Please read the `RUNNING_UNIT_TESTS` file for the details of how to run the unit tests.

* Github: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter
* Gitter: https://gitter.im/rails-sqlserver/activerecord-sqlserver-adapter


## Credits & Contributions

Many many people have contributed. If you do not see your name here and it should be let us know. Also, many thanks go out to those that have pledged financial contributions.


## Contributers
Up-to-date list of contributors: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter/contributors

* metaskills (Ken Collins)
* Annaswims (Annaswims)
* wbond (Will Bond)
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

Copyright © 2008-2016. It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.

