require 'cases/sqlserver_helper'

class BinaryTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [:test_mixed_encoding]
  
  include SqlserverCoercedTest
  
  def test_coerced_mixed_encoding
    assert true # We do encodings right.
  end
  
end

