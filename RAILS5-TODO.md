
## Rails v5.0

* Docs on Docker Usage & Testing - https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/547
* Supports JSON - https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/485
* Supports Comments - https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/486
* Supports Indexed in Create - https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/483
  https://blog.dbi-services.com/sql-server-2014-tips-create-indexes-directly-via-create-table/
  Column Store https://msdn.microsoft.com/en-us/library/gg492153.aspx
  https://www.microsoft.com/en-us/sql-server/developer-get-started/node-mac
* Does the schema cache serialize properly since we conform to that now?
* Can we use `OPTIMIZE FOR UNKNOWN`
  - http://sqlblog.com/blogs/aaron_bertrand/archive/2011/09/17/bad-habits-to-kick-using-exec-instead-of-sp-executesql.aspx
  - http://stackoverflow.com/questions/24016199/sql-server-stored-procedure-become-very-slow-raw-sql-query-is-still-very-fast
  - https://blogs.msdn.microsoft.com/sqlprogrammability/2008/11/26/optimize-for-unknown-a-little-known-sql-server-2008-feature/


## Rails v5.1

* BIGINT PK support. https://github.com/rails/rails/pull/26266

