# AGENTS.md

This file contains guidelines and commands for agentic coding agents working in the ActiveRecord SQL Server Adapter repository.

## Build, Lint & Test Commands

### Core Commands
```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake test

# Run specific test files
bundle exec ruby -Ilib:test test/cases/adapter_test_sqlserver.rb

# Run tests with environment variables
ONLY_SQLSERVER=1 bundle exec rake test
ONLY_ACTIVERECORD=1 bundle exec rake test

# Run specific tests using TEST_FILES environment variable
TEST_FILES=test/cases/adapter_test_sqlserver.rb,test/cases/schema_test_sqlserver.rb bundle exec rake test:dblib

# Run specific ActiveRecord tests using TEST_FILES_AR
TEST_FILES_AR=test/cases/adapters/mysql2/schema_test.rb bundle exec rake test:dblib

# Enable warnings during testing
WARNING=1 bundle exec rake test:dblib

# Run performance profiling
bundle exec rake profile:dblib:[profile_case_name]
```

### Code Quality
```bash
# Run Standard Ruby formatter/linter
bundle exec standardrb

# Run Standard with fix
bundle exec standardrb --fix

# Check only (no modifications)
bundle exec standardrb --format progress
```

## Code Style Guidelines

### General Standards
- **Ruby Version**: Target Ruby 3.2.0+ (uses frozen_string_literal: true)
- **Code Style**: Uses Standard Ruby formatter
- **Line Length**: 120 characters max
- **String Literals**: Double quotes preferred (enforced by RuboCop)
- **Encoding**: Always include `# frozen_string_literal: true` at top of files

### Import/Require Organization
```ruby
# frozen_string_literal: true

# External libraries first
require "tiny_tds"
require "base64"
require "active_record"

# Internal libraries next, grouped by functionality
require "active_record/connection_adapters/sqlserver/version"
require "active_record/connection_adapters/sqlserver/type"
require "active_record/connection_adapters/sqlserver/database_limits"
# ... etc

# Local requires last
require_relative "support/paths_sqlserver"
```

### Naming Conventions
- **Files**: snake_case with `_test_sqlserver.rb` suffix for test files
- **Classes**: PascalCase, test classes end with `SQLServer` suffix
- **Methods**: snake_case, use descriptive names
- **Constants**: SCREAMING_SNAKE_CASE
- **Modules**: PascalCase, logical grouping (e.g., `SQLServer::Type`)

### Module Structure
```ruby
module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Boolean < ActiveRecord::Type::Boolean
          def sqlserver_type
            "bit"
          end
        end
      end
    end
  end
end
```

### Testing Patterns
- **Test Files**: Follow pattern `*_test_sqlserver.rb` in `test/cases/`
- **Test Classes**: Inherit from `ActiveRecord::TestCase`
- **Fixtures**: Use `fixtures :table_name` when needed
- **Let Blocks**: Use `let` for test setup data
- **Assertions**: Use custom assertions from `ARTest::SQLServer::QueryAssertions`

### Error Handling
- Use SQL Server-specific error classes from `ActiveRecord::ConnectionAdapters::SQLServer::Errors`
- Handle TinyTDS errors appropriately
- Log database errors with context

### Type System
- All SQL Server types inherit from corresponding ActiveRecord types
- Implement `sqlserver_type` method for database type mapping
- Location: `lib/active_record/connection_adapters/sqlserver/type/`

### Connection Management
- Use `ActiveRecord::Base.lease_connection` for connection access
- Handle connection pooling and timeout scenarios
- Support both dblib modes

### Schema Statements
- Follow SQL Server-specific SQL syntax
- Use proper identifier quoting with square brackets: `[table_name]`
- Handle SQL Server's quirks around primary keys, indexes, and constraints

## File Organization

### Core Structure
```
lib/
├── active_record/
│   └── connection_adapters/
│       └── sqlserver/           # Main adapter implementation
│           ├── type/            # SQL Server-specific types
│           └── core_ext/        # ActiveRecord extensions
test/
├── cases/                       # Test files (*_test_sqlserver.rb)
├── support/                     # Test utilities and helpers
└── migrations/                  # Test migrations
```

### Module Dependencies
- Core adapter: `lib/active_record/connection_adapters/sqlserver_adapter.rb`
- Types: `lib/active_record/connection_adapters/sqlserver/type.rb`
- Core extensions: `lib/active_record/connection_adapters/sqlserver/core_ext/`

## Development Notes

### Environment Variables
- `ARCONN`: Set to "sqlserver" for testing
- `ARCONFIG`: Path to database configuration file
- `TEST_FILES`: Comma-separated test files to run
- `TEST_FILES_AR`: ActiveRecord test files to run
- `ONLY_SQLSERVER`: Run only SQL Server-specific tests
- `ONLY_ACTIVERECORD`: Run only ActiveRecord tests
- `WARNING`: Enable Ruby warnings during tests

### Dependencies
- **tiny_tds**: SQL Server connectivity (v3.0+)
- **activerecord**: Rails ORM (v8.2.0.alpha)
- **mocha**: Mocking framework for tests
- **minitest**: Testing framework (v6.0+)

### Database Configuration
- Tests use configuration from `test/config.yml`
- Supports SQL Server 2012 and upward
- Requires proper SQL Server connection setup

## Testing Best Practices

### Running Single Tests
```bash
# Run a single test file
bundle exec ruby -Ilib:test test/cases/adapter_test_sqlserver.rb

# Run specific test method
bundle exec ruby -Ilib:test test/cases/adapter_test_sqlserver.rb -n test_method_name
```

### Test Environment Setup
- All test helpers are in `test/support/`
- Use `ARTest::SQLServer` module for test utilities
- Schema loaded via `support/load_schema_sqlserver.rb`

### Test Data
- Use fixtures where appropriate
- Let blocks for test-specific data setup
- Clean database state between tests
