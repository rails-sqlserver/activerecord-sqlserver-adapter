require "cases/helper"
unless defined? TouchTest
  require "cases/mixin_test"
end

# Inherit from TouchTest but change the setup method to have a fixed time without usecs
class TouchForSqlServerTest < TouchTest
  def setup
    t = Time.now
    no_usec_time = Time.gm(t.year, t.month, t.day, t.hour, t.min, t.sec, 0)
    Time.forced_now_time = no_usec_time
  end

  def teardown
    Time.forced_now_time = nil
  end
end
