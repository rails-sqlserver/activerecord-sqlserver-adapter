require 'minitest'
require 'guard/minitest/notifier'

module Guard
  class Minitest < Plugin
    class Reporter < ::Minitest::Reporter
      def report
        aggregate = results.group_by { |r| r.failure.class }
        aggregate.default = [] # dumb. group_by should provide this

        f = aggregate[::Minitest::Assertion].size
        e = aggregate[::Minitest::UnexpectedError].size
        s = aggregate[::Minitest::Skip].size
        t = Time.now - start_time

        ::Guard::Minitest::Notifier.notify(count, assertions, f, e, s, t)
      end
    end
  end
end
