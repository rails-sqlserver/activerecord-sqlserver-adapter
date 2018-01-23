## v5.1.6

#### Added

* Use lock hint when joining table in query.


## v5.1.5

#### Fixed

* Memoize `@@version` queries. Fixes #632


## v5.1.4

#### Fixed

* Add case insensitive comparison for better performance with CI collations. Fixes #624


## v5.1.3

#### Fixed

* Use bigint type in sqlserver_type when needed. Fixes #616


## v5.1.2

#### Fixed

* The `fast_string_to_time` method when zone local. Fixes #609 #614 #620
* Patched `Relation#build_count_subquery`. Fixes #613.
* Inserts to tables with triggers using default `OUTPUT INSERTED` style. Fixes #595.


## v5.1.1

#### Fixed

* Use `ActiveSupport.on_load` to hook into ActiveRecord Fixes #588 #598


## v5.1.0

#### Changed

* The `drop_table` with force cascade option now mimics in via pure SQL for us.

#### Added

* Support MismatchedForeignKey exception.

