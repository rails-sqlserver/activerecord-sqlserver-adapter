module Arel
  module Nodes
    # Extending the Ordering class to be comparison friendly which allows us to call #uniq on a
    # collection of them. See SelectManager#order for more details.
    class Ordering < Arel::Nodes::Unary
      def eql?(other)
        # Arel::Nodes::Ascending or Arel::Nodes::Desecnding
        other.is_a?(Arel::Nodes::Ordering) &&
        expr == other.expr
      end
      alias_method :==, :eql?
    end
  end
end
