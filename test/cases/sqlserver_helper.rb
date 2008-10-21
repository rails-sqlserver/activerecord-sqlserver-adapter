require 'cases/helper'

# See cases/helper in rails/activerecord for why we do this - it'd be nice if there was
# an API for adapaters to influence the tests in this way.  Anyway, it's to tell asser_queries
# to ignore our SELECT SCOPE_IDENTITY stuff.
ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL << /SELECT SCOPE_IDENTITY/
end

