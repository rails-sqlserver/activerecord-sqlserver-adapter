
require "cases/helper_sqlserver"

class DebugTest < ActiveRecord::TestCase

  class Sensor < ActiveRecord::Migration::Current
    attr_reader :went_up, :went_down

    def initialize(name = self.class.name, version = nil)
      super
      @went_up = false
      @went_down = false
    end

    def up; @went_up = true; end
    def down; @went_down = true; end
  end

  def test_migrator_db_has_no_schema_migrations_table
    schema_migration = ActiveRecord::Base.connection.schema_migration
    _, migrator = migrator_class(3)
    migrator = migrator.new("valid", schema_migration)

    ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
      puts payload[:sql]
    end

    puts "*********** 1 ***********"

    ActiveRecord::SchemaMigration.drop_table

    puts "*********** 2 ***********"

    assert_not_predicate ActiveRecord::SchemaMigration, :table_exists?

    puts "*********** 3 ***********"

    migrator.migrate(1)

    puts "*********** 4 ***********"

    assert_predicate ActiveRecord::SchemaMigration, :table_exists?

    puts "*********** 5 ***********"
  end

  private

  def m(name, version)
    x = Sensor.new name, version
    x.extend(Module.new {
      define_method(:up) { yield(:up, x); super() }
      define_method(:down) { yield(:down, x); super() }
    }) if block_given?
  end

  def sensors(count)
    calls = []
    migrations = count.times.map { |i|
      m(nil, i + 1) { |c, migration|
        calls << [c, migration.version]
      }
    }
    [calls, migrations]
  end

  def migrator_class(count)
    calls, migrations = sensors(count)

    migrator = Class.new(ActiveRecord::MigrationContext) {
      define_method(:migrations) { |*|
        migrations
      }
    }
    [calls, migrator]
  end

end
