
# How To Run The Test!

This process is much easier than it has been before!


## TL;DR

Default testing uses DBLIB with TinyTDS.

* Setup two databases in SQL Server, [activerecord_unittest] and [activerecord_unittest2]
* Create a [rails] user with an empty password and give it a [db_owner] role to both DBs. Some tests require a server role of [sysadmin] too.
  - http://twitpic.com/9bsiyp/full
  - http://twitpic.com/9bsj7z/full
  - http://twitpic.com/9bsjdx/full
  - http://twitpic.com/9bsjl7/full
* $ git clone git://github.com/rails-sqlserver/activerecord-sqlserver-adapter.git
* $ bundle install
* $ bundle exec rake test ACTIVERECORD_UNITTEST_HOST='my.db.net'


## Creating the test databases

The default names for the test databases are `activerecord_unittest` and `activerecord_unittest2`. If you want to use another database name then be sure to update the connection file that matches your connection method in test/connections/native_sqlserver_#{connection_method}/connection.rb. Define a user named 'rails' in SQL Server with all privileges granted for the test databases. Use an empty password for said user.

The connection files make certain assumptions. For instance, the ODBC connection assumes you have a DSN setup that matches the name of the default database names. Remember too you have to set an environment variable for the DSN of the adapter, see the connection.rb file that matches your connection mode for details.


## Cloning The Repos

Clone adapter git://github.com/rails-sqlserver/activerecord-sqlserver-adapter.git. The master branch is the one under development for Rails 3, track the repos 2-3-stable branch for 2.x development.

The tests of this adapter depend on the existence of the Rails which under the 3.1 version and above is automatically cloned for you with bundler. However you can clone Rails from git://github.com/rails/rails.git and set the `RAILS_SOURCE` environment variable so bundler will use another local path instead.

```
$ git clone git://github.com/rails-sqlserver/activerecord-sqlserver-adapter.git
```

Optionally, you an just let bundler do all the work and assuming there is a git tag for the Rails version, you can set `RAILS_VERSION` before bundling.

```
$ export RAILS_VERSION='3.2.13'
$ bundle install
```


## Configure DB Connection

Please consult the `test/config.yml` file which is used to parse the configuration options for the DB connections when running tests. This file has overrides for any connection mode that you can set using simple environment variables. Assuming you are using FreeTDS 0.91 and above

```
$ export ACTIVERECORD_UNITTEST_HOST='my.db.net'   # Defaults to localhost
$ export ACTIVERECORD_UNITTEST_PORT='1533'        # Defaults to 1433
```

If you have FreeTDS installed and/or want to use a named dataserver in your freetds.conf file

```
$ export ACTIVERECORD_UNITTEST_DATASERVER='mydbname'
```

These can be passed down to rake too.

```
$ bundle exec rake test ACTIVERECORD_UNITTEST_HOST='my.db.net'
```


## Bundling

Now with that out of the way you can run "bundle install" to hook everything up. Our tests use bundler to setup the load paths correctly. The default mode is DBLIB using TinyTDS. It is important to use bundle exec so we can wire up the ActiveRecord test libs correctly.

```
$ bundle exec rake test
```


## Testing Options

The Gemfile contains groups for `:tinytds` and `:odbc`. By default it will install both gems  which allows you to run the full test suite in either connection mode. If for some reason any one of these is problematic or of no concern, you could always opt out of bundling either gem with something like this.

```
$ bundle install --without odbc
```

You can run different connection modes using the following rake commands. Again, the DBLIB connection mode using TinyTDS is the default test task.

```
$ bundle exec rake test:dblib
$ bundle exec rake test:odbc
```

By default, Bundler will download the Rails git repo and use the git tag that matches the dependency version in our gemspec. If you want to test another version of Rails, you can either temporarily change the :tag for Rails in the Gemfile. Likewise, you can clone the Rails repo your self to another directory and use the `RAILS_SOURCE` environment variable.


## Current Expected Failures

* Misc Date/Time erros when using ODBC mode.
* Misc Date/Time erros when testing SQL Server 2005.
