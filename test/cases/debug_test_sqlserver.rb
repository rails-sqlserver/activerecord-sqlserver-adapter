
require "cases/helper_sqlserver"
require "cases/migration/helper"

# MultiDbMigratorTest
class DebugTest < ActiveRecord::TestCase
  self.use_transactional_tests = false

  # Use this class to sense if migrations have gone
  # up or down.
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

  def setup
    super
    @connection_a = ActiveRecord::Base.connection
    @connection_b = ARUnit2Model.connection

    @connection_a.schema_migration.create_table
    @connection_b.schema_migration.create_table

    @connection_a.schema_migration.delete_all rescue nil
    @connection_b.schema_migration.delete_all rescue nil

    @path_a = MIGRATIONS_ROOT + "/valid"
    @path_b = MIGRATIONS_ROOT + "/to_copy"

    @schema_migration_a = @connection_a.schema_migration
    @migrations_a = ActiveRecord::MigrationContext.new(@path_a, @schema_migration_a).migrations
    @schema_migration_b = @connection_b.schema_migration
    @migrations_b = ActiveRecord::MigrationContext.new(@path_b, @schema_migration_b).migrations

    @migrations_a_list = [[1, "ValidPeopleHaveLastNames"], [2, "WeNeedReminders"], [3, "InnocentJointable"]]
    @migrations_b_list = [[1, "PeopleHaveHobbies"], [2, "PeopleHaveDescriptions"]]

    @verbose_was = ActiveRecord::Migration.verbose

    ActiveRecord::Migration.message_count = 0
    ActiveRecord::Migration.class_eval do
      undef :puts
      def puts(*)
        ActiveRecord::Migration.message_count += 1
      end
    end
  end

  teardown do
    @connection_a.schema_migration.delete_all rescue nil
    @connection_b.schema_migration.delete_all rescue nil

    ActiveRecord::Migration.verbose = @verbose_was
    ActiveRecord::Migration.class_eval do
      undef :puts
      def puts(*)
        super
      end
    end
  end


  def test_migrator_db_has_no_schema_migrations_table
    _, migrator = migrator_class(3)
    migrator = migrator.new(@path_a, @schema_migration_a)

    @schema_migration_a.drop_table
    assert_not @connection_a.table_exists?("schema_migrations")
    migrator.migrate(1)
    assert @connection_a.table_exists?("schema_migrations")

    _, migrator = migrator_class(3)
    migrator = migrator.new(@path_b, @schema_migration_b)

    @schema_migration_b.drop_table
    assert_not @connection_b.table_exists?("schema_migrations")
    migrator.migrate(1)
    assert @connection_b.table_exists?("schema_migrations")
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
