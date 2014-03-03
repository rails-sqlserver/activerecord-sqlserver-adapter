module Arel
  class SelectManager < Arel::TreeManager
    AR_CA_SQLSA_NAME = 'ActiveRecord::ConnectionAdapters::SQLServerAdapter'.freeze

    # Getting real Ordering objects is very important for us. We need to be able to call #uniq on
    # a colleciton of them reliably as well as using their true object attributes to mutate them
    # to grouping objects for the inner sql during a select statment with an offset/rownumber. So this
    # is here till ActiveRecord & ARel does this for us instead of using SqlLiteral objects.
    alias_method :order_without_sqlserver, :order
    def order(*expr)
      return order_without_sqlserver(*expr) unless engine_activerecord_sqlserver_adapter?
      @ast.orders.concat(expr.map do |x|
        case x
        when Arel::Attributes::Attribute
          table = Arel::Table.new(x.relation.table_alias || x.relation.name)
          e = table[x.name]
          Arel::Nodes::Ascending.new e
        when Arel::Nodes::Ordering
          x
        when String
          x.split(',').map do |s|
            s = x if x.strip =~ /\A\b\w+\b\(.*,.*\)(\s+(ASC|DESC))?\Z/i # Allow functions with comma(s) to pass thru.
            s.strip!
            d = s =~ /(ASC|DESC)\Z/i ? Regexp.last_match[1].upcase : nil
            e = d.nil? ? s : s.mb_chars[0...-d.length].strip
            e = Arel.sql(e)
            d && d == 'DESC' ? Arel::Nodes::Descending.new(e) : Arel::Nodes::Ascending.new(e)
          end
        else
          e = Arel.sql(x.to_s)
          Arel::Nodes::Ascending.new e
        end
      end.flatten)
      self
    end

    # A friendly over ride that allows us to put a special lock object that can have a default or pass
    # custom string hints down. See the visit_Arel_Nodes_LockWithSQLServer delegation method.
    alias_method :lock_without_sqlserver, :lock
    def lock(locking = true)
      if engine_activerecord_sqlserver_adapter?
        case locking
        when true
          locking = Arel.sql('WITH(HOLDLOCK, ROWLOCK)')
        when Arel::Nodes::SqlLiteral
        when String
          locking = Arel.sql locking
        end
        @ast.lock = Arel::Nodes::Lock.new(locking)
        self
      else
        lock_without_sqlserver(locking)
      end
    end

    private

    def engine_activerecord_sqlserver_adapter?
      @engine.connection && @engine.connection.class.name == AR_CA_SQLSA_NAME
    end
  end
end
