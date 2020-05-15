# frozen_string_literal: true

module ActiveRecord
  class DeadlockVictim < WrappedDatabaseException
  end
end
