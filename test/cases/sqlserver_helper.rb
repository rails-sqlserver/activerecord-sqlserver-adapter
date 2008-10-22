require 'cases/helper'

class TableWithRealColumn < ActiveRecord::Base; end

# See cases/helper in rails/activerecord. Tell assert_queries to ignore 
# our SELECT SCOPE_IDENTITY stuff.
ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL << /SELECT SCOPE_IDENTITY/
end


