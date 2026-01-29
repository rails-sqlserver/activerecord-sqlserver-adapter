require 'guard/compat/plugin'

module Guard
  class Minitest < Plugin
    class Notifier
      def self.guard_message(test_count, assertion_count, failure_count, error_count, skip_count, duration)
        message = "#{test_count} tests"
        message << " (#{skip_count} skipped)" if skip_count > 0
        message << "\n#{assertion_count} assertions, #{failure_count} failures, #{error_count} errors"
        if test_count && assertion_count
          message << "\n\n%.2f tests/s, %.2f assertions/s\n\nFinished in %.4f seconds" % [test_count / duration, assertion_count / duration, duration]
        end
        message
      end

      # failed | pending (skip) | success
      def self.guard_image(failure_count, skip_count)
        if failure_count > 0
          :failed
        elsif skip_count > 0
          :pending
        else
          :success
        end
      end

      def self.notify(test_count, assertion_count, failure_count, error_count, skip_count, duration)
        message = guard_message(test_count, assertion_count, failure_count, error_count, skip_count, duration)
        image   = guard_image(failure_count + error_count, skip_count)

        Compat::UI.notify(message, title: 'Minitest results', image: image)
      end
    end
  end
end
