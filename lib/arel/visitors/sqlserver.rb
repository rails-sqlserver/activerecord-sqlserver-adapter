module Arel
  module Visitors
    class SQLServer < Arel::Visitors::ToSql

      OFFSET = " OFFSET "
      ROWS = " ROWS"
      FETCH = " FETCH NEXT "
      ROWS_ONLY = " ROWS ONLY"


      private

      # SQLServer ToSql/Visitor (Overides)

      def visit_Arel_Nodes_BindParam o, collector
        collector.add_bind(o) { |i| "@#{i-1}" }
      end

      def visit_Arel_Nodes_Offset o, collector
        collector << OFFSET
        visit o.expr, collector
        collector << ROWS
      end

      def visit_Arel_Nodes_Limit o, collector
        collector << FETCH
        visit o.expr, collector
        collector << ROWS_ONLY
      end

      def visit_Arel_Nodes_SelectStatement o, collector
        if o.with
          collector = visit o.with, collector
          collector << SPACE
        end
        collector = o.cores.inject(collector) { |c,x|
          visit_Arel_Nodes_SelectCore(x, c)
        }
        collector = visit_Orders_And_Let_Fetch_Happen o, collector
        collector = visit_Make_Fetch_Happen o, collector
        collector = visit o.lock, collector if o.lock
        collector
      end

      # SQLServer ToSql/Visitor (Additions)

      def visit_Orders_And_Let_Fetch_Happen o, collector
        if (o.limit || o.offset) && o.orders.empty?
          table = table_From_Statement o
          column = table.primary_key || table.columns.first
          o.orders = [column.asc]
        end
        unless o.orders.empty?
          collector << SPACE
          collector << ORDER_BY
          len = o.orders.length - 1
          o.orders.each_with_index { |x, i|
            collector = visit(x, collector)
            collector << COMMA unless len == i
          }
        end
        collector
      end

      def visit_Make_Fetch_Happen o, collector
        o.offset = Nodes::Offset.new(0) if o.limit && !o.offset
        collector = visit o.offset, collector if o.offset
        collector = visit o.limit, collector if o.limit
        collector
      end

      # SQLServer Helpers

      def table_From_Statement o
        core = o.cores.first
        if Arel::Table === core.from
          core.from
        elsif Arel::Nodes::SqlLiteral === core.from
          Arel::Table.new(core.from)
        elsif Arel::Nodes::JoinSource === core.source
          Arel::Nodes::SqlLiteral === core.source.left ? Arel::Table.new(core.source.left, @engine) : core.source.left
        end
      end

    end
  end
end

Arel::Visitors::VISITORS['sqlserver'] = Arel::Visitors::SQLServer
