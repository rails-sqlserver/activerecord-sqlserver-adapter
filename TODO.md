
## SHORT TERM

Misc remidners while in the heat of adapting the adpater.

* Review coerced tests.

## LONG TERM

After we get some tests passing

* Is `primary_keys(table_name)` performant? Contribute to rails for abstract adapter.
* Check `sql_for_insert` can do without the table regular expresion.
* Do we need the `query_requires_identity_insert` check in `execute`?
* Does the schema cache serialize properly since we conform to that now?


#### Does Find By SQL Work?

With binds and prepareable?

```ruby
#   Post.find_by_sql ["SELECT title FROM posts WHERE author = ? AND created > ?", author_id, start_date]
#   Post.find_by_sql ["SELECT body FROM comments WHERE author = :user_id OR approved_by = :user_id", { :user_id => user_id }]
#
def find_by_sql(sql, binds = [], preparable: nil)
  result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds, preparable: preparable)
```
