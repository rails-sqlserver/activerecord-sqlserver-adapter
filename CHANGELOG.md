## v5.1.3

#### Fixed

* Patched `Relation#build_count_subquery`. Fixes #613.


## v5.1.2

#### Fixed

* The `fast_string_to_time` method when zone local. Fixes #609 #614 #620


## v5.1.1

#### Fixed

* Use `ActiveSupport.on_load` to hook into ActiveRecord Fixes #588 #598


## v5.1.0

#### Changed

* The `drop_table` with force cascade option now mimics in via pure SQL for us.

#### Added

* Support MismatchedForeignKey exception.

