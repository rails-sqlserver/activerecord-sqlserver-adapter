## v6.0.0.rc2

#### Fixed

- [#639](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/639) Primary key should be lowercase if schema forced to lowercase
- [#720](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/720) quoted_date doesn't work for Type::DateTime

#### Changed

- [#826](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/826) Rubocop: Enable Style/StringLiterals cop
- [#827](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/827) Rubocop: Enable Layout/EmptyLinesAroundClassBody cop
- [#828](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/828) Rubocop: Enable Layout/EmptyLines cop
- [#829](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/829) Rubocop: Enable Layout/Layout/EmptyLinesAround* cops
- [#830](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/830) Rubocop: Enable Layout/IndentationWidth and Layout/TrailingWhitespace cops
- [#831](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/831) Rubocop: Enable Spacing cops
- [#832](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/832) Rubocop: Enable Bundler cops
- [#833](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/833) Rubocop: Enable Layout/* cops
- [#834](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/834) Rubocop: Enable Lint/UselessAssignment cop
- [#835](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/835) Rubocop: Configure Naming cops

## v6.0.0.rc1

#### Fixed

- [#690](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/690) Rails 6 support
- [#805](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/805) Rails 6: Fix database tasks tests for SQL Server
- [#807](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/807) Rails 6: Skip binary fixtures test on Windows
- [#809](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/809) Rails 6: Coerce reaper test using fork
- [#810](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/810) Rails 6: Fix randomly failing tests due to schema load
- [#812](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/812) Rails 6: Coerce ReloadModelsTest test on Windows
- [#818](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/818) Handle false return by TinyTDS if connection fails and fixed CI
- [#819](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/819) Fix Ruby 2.7 kwargs warnings
- [#825](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/825) Adjust error message when connection is dead

#### Changed

- [#716](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/716) Translate the connection timed out error
- [#763](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/763) Refactor columns introspection query to make it faster
- [#783](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/783) Update test matrix
- [#820](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/820) Enable frozen strings for tests
- [#821](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/821) Enable frozen strings - part 1
- [#822](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/822) Enable frozen strings - part 2
- [#823](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/823) Enable frozen strings - final
- [#824](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/824) Tidy up Gemfile

#### Added

- [#726](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/pull/726) How to Develop ActiveRecord SQL Server Adapter with Pre-Installed MS SQL

Please check [5-2-stable](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/5-2-stable/CHANGELOG.md) for previous changes.
