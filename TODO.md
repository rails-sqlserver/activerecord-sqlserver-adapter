
## SHORT TERM

Misc remidners while in the heat of adapting the adpater.

* Try removing `sp_executesql_sql_type` all together. Do we have to add more types?
* Did we get the schema cache right?



## LONG TERM

After we get some tests passing

* Is `primary_keys(table_name)` performant? Contribute to rails for abstract adapter.
* Check `sql_for_insert` can do without the table regular expresion.
* Do we need the `query_requires_identity_insert` check in `execute`?
* Will we have to add more Data types to our dates and use them in `quoted_date` or `quoted_string` or `_type_cast`?


#### Use #without_prepared_statement?

I think we always send everything thru `sp_executesql`. Consider re-evaulating if there are no `binds` that we get any benefit from this. By doing so we also give the users the ability to turn this off completly. Would be neat to see how our prepared statments actually perform again.

```ruby
def without_prepared_statement?(binds)
  !prepared_statements || binds.empty?
end
```

Maybe just quick bail to `do_execute`. Maybe related:

* [Do not cache prepared statements that are unlikely to have cache hits](https://github.com/rails/rails/commit/cbcdecd2)




#### Does Find By SQL Work?

With binds and prepareable?

```ruby
#   Post.find_by_sql ["SELECT title FROM posts WHERE author = ? AND created > ?", author_id, start_date]
#   Post.find_by_sql ["SELECT body FROM comments WHERE author = :user_id OR approved_by = :user_id", { :user_id => user_id }]
#
def find_by_sql(sql, binds = [], preparable: nil)
  result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds, preparable: preparable)
```
