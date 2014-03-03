require 'cases/sqlserver_helper'
require 'action_dispatch'

module ActiveRecord
  class SessionStore
    class SessionTest < ActiveRecord::TestCase

      setup :reset_column_information_for_each_test

      protected

      def reset_column_information_for_each_test
        Session.reset_column_information
      end

    end
  end
end
