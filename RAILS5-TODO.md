
## SHORT TERM

Misc remidners while in the heat of adapting the adpater.


## TEST FAILURE SUMMARY

I am currently using `TESTOPTS="--seed=44527"` to get a consistant order for now. Also, the CI suite is locked down to using `ONLY_SQLSERVER=1` to make PRs feel good. Soon we will want to change this.

* 10 - AttributeMethodsTest
*  6 - FinderTest
*  6 - Gem `sqlite3` load error.
*  6 - UniquenessValidationTest
*  4 - RelationTest
*  4 - MigrationTest
*  4 - (HasMany|HasAndBelongs)AssociationsTest
*  3 - AdapterTest
*  3 - TransactionCallbacksTest
*  2 - NamedScopingTest
*  2 - DefaultNumbersTest
*  2 - DefaultScopingTest
*  2 - CalculationsTest
*  2 - MultipleDbTest
*  2 - EachTest
*  2 - ColumnsTest
*  2 - SchemaDumperTest
*  1 - BasicsTest
*  1 - MultiParameterAttributeTest
*  1 - QuoteBooleanTest
*  1 - LeftOuterJoinAssociationTest
*  1 - EagerAssociationTest
*  1 - DateTest


## LONG TERM

After we get some tests passing

* Check `sql_for_insert` can do without the table regular expresion.
* Do we need the `query_requires_identity_insert` check in `execute`?
* Does the schema cache serialize properly since we conform to that now?
* What does `supports_materialized_views?` means for SQL Server
  - http://michaeljswart.com/2014/12/materialized-views-in-sql-server/
  - https://blogs.msdn.microsoft.com/ssma/2011/06/20/migrating-oracle-materialized-view-to-sql-server/
  - http://stackoverflow.com/questions/3986366/how-to-create-materialized-views-in-sql-server
* BIGINT PK support. https://github.com/rails/rails/pull/26266
* Can we use `OPTIMIZE FOR UNKNOWN`
  - http://sqlblog.com/blogs/aaron_bertrand/archive/2011/09/17/bad-habits-to-kick-using-exec-instead-of-sp-executesql.aspx
  - http://stackoverflow.com/questions/24016199/sql-server-stored-procedure-become-very-slow-raw-sql-query-is-still-very-fast
  - https://blogs.msdn.microsoft.com/sqlprogrammability/2008/11/26/optimize-for-unknown-a-little-known-sql-server-2008-feature/
* Re-visit all `current_adapter?(:PostgreSQLAdapter)` checks and find ones we can play in.


#### Does Find By SQL Work?

With binds and prepareable?

```ruby
#   Post.find_by_sql ["SELECT title FROM posts WHERE author = ? AND created > ?", author_id, start_date]
#   Post.find_by_sql ["SELECT body FROM comments WHERE author = :user_id OR approved_by = :user_id", { :user_id => user_id }]
#
def find_by_sql(sql, binds = [], preparable: nil)
  result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds, preparable: preparable)
```
