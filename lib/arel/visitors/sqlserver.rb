module Arel
  module Visitors
    class SQLServer < Arel::Visitors::ToSql
      
      
      
    end
  end
end

Arel::Visitors::VISITORS['sqlserver'] = Arel::Visitors::SQLServer
