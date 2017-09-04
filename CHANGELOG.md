## v5.1.2

* Fix `fast_string_to_time` with local support. Fixes #614. Thanks @wpolicarpo


## v5.1.1

#### Fixed

* Use `ActiveSupport.on_load` to hook into ActiveRecord Fixes #588 #598


## v5.1.0

#### Changed

* The `drop_table` with force cascade option now mimics in via pure SQL for us.

#### Added

* Support MismatchedForeignKey exception.

