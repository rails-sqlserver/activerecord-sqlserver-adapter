module Arel
  module Visitors
    class SQLServer < Arel::Visitors::ToSql

      OFFSET = " OFFSET "
      ROWS = " ROWS"
      FETCH = " FETCH NEXT "
      FETCH0 = " FETCH FIRST (SELECT 0) "
      ROWS_ONLY = " ROWS ONLY"


      private

      # SQLServer ToSql/Visitor (Overides)

      def visit_Arel_Nodes_BindParam o, collector
        collector.add_bind(o) { |i| "@#{i-1}" }
      end

      def visit_Arel_Nodes_Bin o, collector
        visit o.expr, collector
        if o.expr.val.is_a? Numeric
          collector
        else
          collector << " #{ActiveRecord::ConnectionAdapters::SQLServerAdapter.cs_equality_operator} "
        end
      end

      def visit_Arel_Nodes_UpdateStatement(o, a)
        if o.orders.any? && o.limit.nil?
          o.limit = Nodes::Limit.new(9_223_372_036_854_775_807)
        end
        super
      end

      def visit_Arel_Nodes_Lock o, collector
        o.expr = Arel.sql('WITH (UPDLOCK)') if o.expr.to_s =~ /FOR UPDATE/
        collector << SPACE
        visit o.expr, collector
      end

      def visit_Arel_Nodes_Offset o, collector
        collector << OFFSET
        visit o.expr, collector
        collector << ROWS
      end

      def visit_Arel_Nodes_Limit o, collector
        if node_value(o) == 0
          collector << FETCH0
          collector << ROWS_ONLY
        else
          collector << FETCH
          visit o.expr, collector
          collector << ROWS_ONLY
        end
      end

      def visit_Arel_Nodes_SelectStatement o, collector
        @select_statement = o
        if o.with
          collector = visit o.with, collector
          collector << SPACE
        end
        collector = o.cores.inject(collector) { |c,x|
          visit_Arel_Nodes_SelectCore(x, c)
        }
        collector = visit_Orders_And_Let_Fetch_Happen o, collector
        collector = visit_Make_Fetch_Happen o, collector
        collector
      ensure
        @select_statement = nil
      end

      def visit_Arel_Nodes_JoinSource o, collector
        if o.left
          collector = visit o.left, collector
          collector = visit_Arel_Nodes_SelectStatement_SQLServer_Lock collector
        end
        if o.right.any?
          collector << " " if o.left
          collector = inject_join o.right, collector, ' '
        end
        collector
      end

      def visit_Arel_Nodes_OuterJoin o, collector
        collector << "LEFT OUTER JOIN "
        collector = visit o.left, collector
        collector = visit_Arel_Nodes_SelectStatement_SQLServer_Lock collector, space: true
        collector << " "
        visit o.right, collector
      end

      # SQLServer ToSql/Visitor (Additions)

      def visit_Arel_Nodes_SelectStatement_SQLServer_Lock collector, options = {}
        if select_statement_lock?
          collector = visit @select_statement.lock, collector
          collector << SPACE if options[:space]
        end
        collector
      end

      def visit_Orders_And_Let_Fetch_Happen o, collector
        if (o.limit || o.offset) && o.orders.empty?
          table = table_From_Statement o
          column = primary_Key_From_Table(table)
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

      def node_value(node)
        case node.expr
        when NilClass then nil
        when Numeric then node.expr
        when Arel::Nodes::Unary then node.expr.expr
        end
      end

      def select_statement_lock?
        @select_statement && @select_statement.lock
      end

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

      def primary_Key_From_Table t
        return t.primary_key if t.primary_key
        if engine_pk = t.engine.primary_key
          pk = t.engine.arel_table[engine_pk]
          return pk if pk
        end
        pk = t.engine.connection.schema_cache.primary_keys(t.engine.table_name)
        return pk if pk
        column_name = t.engine.columns.first.try(:name)
        column_name ? t[column_name] : nil
      end

    end
  end
end

Arel::Visitors::VISITORS['sqlserver'] = Arel::Visitors::SQLServer
