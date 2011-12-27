# Database mirroring support

This adapter has basic support for database mirroring.
In case of failed connection to primary server, adapter will try to connect to mirror.

## Configure

Add :mirror section to your database.yml with mirror server specific connection params:

    :adapter => 'sqlserver',
    :mode => 'dblib',
    :username => 'rails',
    :password => '',
    :database => 'activerecord_unittest_mirroring',
    :dataserver => 'primary_server',
    :mirror
      :dataserver => 'mirror_sql_server'
            
## Model introspection

There are few mirroring introspection methods added to every active record class:

  * db\_mirroring\_status
  * db\_mirroring\_active?
  * db\_mirroring\_synchronized?
  * server_name

## Testing

### Set up mirrored database:

   * create 'activerecord\_unittest\_mirroring' database
   * add 'rails' user as database owner
   * configure database mirroring - worksome (here is a screen-shot tutorial: http://www.sqlserver-training.com/how-to-setup-mirroring-in-sql-server-screen-shots/-)
   * create same (rails) user on another server with same sid

### Set up environment:

 * for dblib 

        ENV['ACTIVERECORD_UNITTEST_DATASERVER_PRIMARY']
        ENV['ACTIVERECORD_UNITTEST_DATASERVER_MIRROR']
     
 * for odbc
 
        ENV['ACTIVERECORD_UNITTEST_DSN_PRIMARY']
        ENV['ACTIVERECORD_UNITTEST_DSN_MIRROR']

### Running tests

 * for dblib mode:
 
        rake test:mirroring:dblib 
     
 * for odbc mode:
 
        rake test:mirroring:odbc
    

Test will create table 'programmers', insert a record, force failover to mirror server, insert second record, force failover back to primary, and insert third record.

