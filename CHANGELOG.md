## v5.2.0.rc1

#### Fixed

- #638 Don't disable referential integrity for the same table twice.
- #646 Make String equality check work for Type::Data values. Fixes #645.
- #671 Fix tinyint columns schema migration. Fixes #670.

#### Changed

- #642 Added with (nolock) hint to information_schema.views.


Please check [5-1-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/5-1-stable/CHANGELOG.md) for previous changes.
