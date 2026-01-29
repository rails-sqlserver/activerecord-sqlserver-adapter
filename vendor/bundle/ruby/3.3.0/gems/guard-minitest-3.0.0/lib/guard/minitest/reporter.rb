require 'minitest'
require 'guard/minitest/notifier'

module Guard
  class Minitest < Plugin
    class Reporter < ::Minitest::StatisticsReporter
      def report
        super

        ::Guard::Minitest::Notifier.notify(count, assertions,
                                           failures, errors,
                                           skips, total_time)
      end
    end
  end
end
