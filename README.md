# ActiveRecord SQL Server Adapter. For SQL Server 2012 And Higher.

* [![CI](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/actions/workflows/ci.yml/badge.svg)](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/actions/workflows/ci.yml) - CI
* [![Build Status](https://ci.appveyor.com/api/projects/status/mtgbx8f57vr7k2qa/branch/master?svg=true)](https://ci.appveyor.com/project/rails-sqlserver/activerecord-sqlserver-adapter/branch/master) - Appveyor
* [![Gem Version](http://img.shields.io/gem/v/activerecord-sqlserver-adapter.svg)](https://rubygems.org/gems/activerecord-sqlserver-adapter) - Gem Version
* [![Gitter chat](https://img.shields.io/badge/%E2%8A%AA%20GITTER%20-JOIN%20CHAT%20%E2%86%92-brightgreen.svg?style=flat)](https://gitter.im/rails-sqlserver/activerecord-sqlserver-adapter) - Community

## About The Adapter

The SQL Server adapter for ActiveRecord using SQL Server 2012 or higher.

Interested in older versions? We follow a rational versioning policy that tracks Rails. That means that our 7.x version of the adapter is only for the latest 7.x version of Rails. If you need the adapter for SQL Server 2008 or 2005, you are still in the right spot. Just install the latest 3.2.x to 4.1.x version of the adapter that matches your Rails version. We also have stable branches for each major/minor release of ActiveRecord.

| Adapter Version | Rails Version | Support | Branch                                                                                           |
|-----------------|---------------|---------|--------------------------------------------------------------------------------------------------|
| `7.1.0`         | `7.1.x`       | Active  | [main](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/main)              |
| `7.0.5.1`       | `7.0.x`       | Active  | [7-0-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/7-0-stable)  |
| `6.1.3.0`       | `6.1.x`       | Active  | [6-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/6-1-stable)  |
| `6.0.3`         | `6.0.x`       | Ended   | [6-0-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/6-0-stable)  |
| `5.2.1`         | `5.2.x`       | Ended   | [5-2-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/5-2-stable)  |
| `5.1.6`         | `5.1.x`       | Ended   | [5-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/5-1-stable)  |
| `4.2.18`        | `4.2.x`       | Ended   | [4-2-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/4-2-stable)  |
| `4.1.8`         | `4.1.x`       | Ended   | [4-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/4-1-stable)  |

For older versions, please check their stable branches.

#### Native Data Type Support

We support every data type supported by FreeTDS. All simplified Rails types in migrations will correspond to a matching SQL Server national (unicode) data type. Always check the `initialize_native_database_types` [(here)](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/master/lib/active_record/connection_adapters/sqlserver/schema_statements.rb) for an updated list.

The following types (`date`, `datetime2`, `datetimeoffset`, `time`) all require TDS version `7.3` with TinyTDS. We recommend using FreeTDS 1.0 or higher which default to using `TDSVER` to `7.3`. The adapter also sets TinyTDS's `tds_version` to this as well if non is specified.

The adapter supports ActiveRecord's `datetime_with_precision` setting. This means that passing `:precision` to a datetime column is supported.

By default, precision 6 is used for `:datetime` types if precision is not specified. Any non-nil precision will tell
the adapter to use the `datetime2` column type. To create a `datetime` column using a migration a precision of `nil`
should be specified, otherwise the precision will default to 6 and a `datetime2` column will be created.


#### Identity Inserts with Triggers

The adapter uses `OUTPUT INSERTED` so that we can select any data type key, for example UUID tables. However, this poses a problem with tables that use triggers. The solution requires that we use a more complex insert statement which uses a temporary table to select the inserted identity. To use this format you must declare your table exempt from the simple output inserted style with the table name into a concurrent hash. Optionally, you can set the data type of the table's primary key to return.

```ruby
adapter = ActiveRecord::ConnectionAdapters::SQLServerAdapter

# Will assume `bigint` as the id key temp table type.
adapter.exclude_output_inserted_table_names['my_table_name'] = true

# Explicitly set the data type for the temporary key table.
adapter.exclude_output_inserted_table_names['my_uuid_table_name'] = 'uniqueidentifier'
```


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

It's also possible to create/change/drop a schema in the migration file as in the example below:

```ruby
class CreateFooSchema < ActiveRecord::Migration[7.0]
  def up
    create_schema('foo')

    # Or you could move a table to a different schema

    change_table_schema('foo', 'dbo.admin')
  end

  def down
    drop_schema('foo')
  end
end
```


#### Configure Connection

The adapter conforms to the AbstractAdapter interface to configure connections. If you require additional connection
configuration then implement the `configure_connection` method in an initializer like so. In the following
example we are setting the `TEXTSIZE` to 64 megabytes.

```ruby
module ActiveRecord
  module ConnectionAdapters
    class SQLServerAdapter < AbstractAdapter
      def configure_connection
        super
        raw_connection_do "SET TEXTSIZE #{64.megabytes}"
      end
    end
  end
end
```

#### Configure Application Name

TinyTDS supports an application name when it logs into SQL Server. This can be used to identify the connection in SQL Server's activity monitor. By default it will use the `appname` from your database.yml file or your Rails::Application name.

Below shows how you might use the database.yml file to use the process ID in your application name.

```yaml
development:
  adapter: sqlserver
  appname: <%= "myapp_#{Process.pid}" %>
```

#### Executing Stored Procedures

Every class that sub classes ActiveRecord::Base will now have an execute_procedure class method to use. This method takes the name of the stored procedure which can be a string or symbol and any number of variables to pass to the procedure. Arguments will automatically be quoted per the connection's standards as normal. For example:

```ruby
Account.execute_procedure(:update_totals, 'admin', nil, true)
# Or with named parameters.
Account.execute_procedure(:update_totals, named: 'params')
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


## New Rails Applications

When creating a new Rails application you can specify that you want to use the SQL Server adapter using the `database` option:

```
rails new my_app --database=sqlserver
```

To then connect the application to your SQL Server instance edit the `config/database.yml` file with the username, password and host of your SQL Server instance.


## Installation

The adapter has no strict gem dependencies outside of `ActiveRecord` and
[TinyTDS](https://github.com/rails-sqlserver/tiny_tds).

```ruby
gem 'activerecord-sqlserver-adapter'
```

## Contributing

If you would like to contribute a feature or bugfix, thanks! To make sure your fix/feature has a high chance of being added, please read the following guidelines. First, ask on the Gitter, or post a ticket on github issues. Second, make sure there are tests! We will not accept any patch that is not tested. Please read the [`RUNNING_UNIT_TESTS`](RUNNING_UNIT_TESTS.md) file for the details of how to run the unit tests.

* Github: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter
* Gitter: https://gitter.im/rails-sqlserver/activerecord-sqlserver-adapter


## Credits & Contributions

Many many people have contributed. If you do not see your name here and it should be let us know. Also, many thanks go out to those that have pledged financial contributions.

You can see an up-to-date list of contributors here: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter/contributors


## License

ActiveRecord SQL Server Adapter is released under the [MIT License](https://opensource.org/licenses/MIT).
