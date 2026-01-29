require 'rubygems/requirement'

require 'guard/minitest'

module Guard
  class Minitest < Plugin
    class Utils
      def self.minitest_version
        @@minitest_version ||= begin
          require 'minitest'
          ::Minitest::VERSION

        rescue LoadError, NameError
          require 'minitest/unit'
          ::MiniTest::Unit::VERSION
        end
      end
    end
  end
end
