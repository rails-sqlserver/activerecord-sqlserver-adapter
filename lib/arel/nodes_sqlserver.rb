module Arel
  module Nodes

    # Extending the Ordering class to be comparison friendly which allows us to call #uniq on a
    # collection of them. See SelectManager#order for more details.
    class Ordering < Arel::Nodes::Unary
      def hash
        expr.hash
      end
      def ==(other)
        other.is_a?(Arel::Nodes::Ordering) && self.expr == other.expr
      end
      def eql?(other)
        self == other
      end
    end

  end
end