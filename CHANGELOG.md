## v7.1.4

#### Fixed

- [#1164](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1164) Fix composite primary key with different data type with triggers

#### Changed

- [#1199](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1199) Remove ActiveRecord::Relation#calculate patch

## v7.1.3

#### Fixed

- [#1152](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1152) Fix Composite Key Inserts with Triggers

## v7.1.2

#### Fixed

- [#1151](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1151) FROM subquery should work if order provided

## v7.1.1

#### Fixed

- [#1145](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1145) Ensure correct order of COLLATE and NOT NULL in CREATE TABLE statements
- [#1144](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1144) Fix precision handling in time migration
- [#1143](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1143) Fix precision handling for datetimeoffset migration

## v7.1.0

#### Added

- [#1141](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1141) Added support for check constraints.

## v7.1.0.rc2

#### Added

- [#1136](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1136) Prevent marking broken connections as verified
- [#1138](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/1138) Cache quoted names

## v7.1.0.rc1

#### Added

* Rails 7.1 Support

  The adapter supports new Rails 7.1 features such as composite primary keys. See the
  [Rails 7.1 release notes](https://guides.rubyonrails.org/7_1_release_notes.html) for more information.

#### Changed

* Configure Connection

  If you require additional connection configuration you now need to call `super` within the `configure_connection`
  method so that the default configuration is also applied.

  v7.1.x adapter:
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

  v7.0.x adapter:
  ```ruby
  module ActiveRecord
    module ConnectionAdapters
      class SQLServerAdapter < AbstractAdapter
        def configure_connection
          raw_connection_do "SET TEXTSIZE #{64.megabytes}"
        end
      end
    end
  end
  ```

Please check [7-0-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/7-0-stable/CHANGELOG.md) for previous changes.
