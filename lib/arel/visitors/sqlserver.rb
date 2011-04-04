require 'arel'

module Arel

  module Nodes

    # See the SelectManager#lock method on why this custom class is needed.
    class LockWithSQLServer < Arel::Nodes::Unary
    end

    # Extending the Ordering class to be comparrison friendly which allows us to call #uniq on a
    # collection of them. See SelectManager#order for more details.
    class Ordering < Arel::Nodes::Binary
      def hash
        expr.hash
      end
      def ==(other)
        self.class == other.class && self.expr == other.expr
      end
      def eql?(other)
        self == other
      end
    end

  end

  class SelectManager < Arel::TreeManager

    alias :lock_without_sqlserver :lock

    # Getting real Ordering objects is very important for us. We need to be able to call #uniq on
    # a colleciton of them reliably as well as using their true object attributes to mutate them
    # to grouping objects for the inner sql during a select statment with an offset/rownumber. So this
    # is here till ActiveRecord & ARel does this for us instead of using SqlLiteral objects.
    def order(*exprs)
      @ast.orders.concat(exprs.map{ |x|
        case x
        when Arel::Attributes::Attribute
          table = Arel::Table.new(x.relation.table_alias || x.relation.name)
          expr = table[x.name]
          Arel::Nodes::Ordering.new expr
        when String
          x.split(',').map do |s|
            expr, direction = s.split
            expr = Arel.sql(expr)
            direction = direction =~ /desc/i ? :desc : :asc
            Arel::Nodes::Ordering.new expr, direction
          end
        else
          expr = Arel.sql(x.to_s)
          Arel::Nodes::Ordering.new expr
        end
      }.flatten)
      self
    end

    # A friendly over ride that allows us to put a special lock object that can have a default or pass
    # custom string hints down. See the visit_Arel_Nodes_LockWithSQLServer delegation method.
    def lock(locking=true)
      if Arel::Visitors::SQLServer === @visitor
        @ast.lock = Arel::Nodes::LockWithSQLServer.new(locking)
        self
      else
        lock_without_sqlserver(locking)
      end
    end

  end

  module Visitors
    class SQLServer < Arel::Visitors::ToSql

      private

      # SQLServer ToSql/Visitor (Overides)

      def visit_Arel_Nodes_SelectStatement(o)
        if complex_count_sql?(o)
          visit_Arel_Nodes_SelectStatementForComplexCount(o)
        elsif o.offset
          visit_Arel_Nodes_SelectStatementWithOffset(o)
        else
          visit_Arel_Nodes_SelectStatementWithOutOffset(o)
        end
      end

      def visit_Arel_Nodes_Offset(o)
        "WHERE [__rnt].[__rn] > (#{visit o.expr})"
      end

      def visit_Arel_Nodes_Limit(o)
        "TOP (#{visit o.expr})"
      end

      def visit_Arel_Nodes_Lock o
        "WITH(HOLDLOCK, ROWLOCK)"
      end

      def visit_Arel_Nodes_LockWithSQLServer o
        case o.expr
        when TrueClass
          "WITH(HOLDLOCK, ROWLOCK)"
        when String
          o.expr
        else
          ""
        end
      end


      # SQLServer ToSql/Visitor (Additions)

      def visit_Arel_Nodes_SelectStatementWithOutOffset(o, windowed=false)
        find_and_fix_uncorrelated_joins_in_select_statement(o)
        core = o.cores.first
        projections = core.projections
        groups = core.groups
        orders = o.orders.uniq
        if windowed
          projections = function_select_statement?(o) ? projections : projections.map { |x| projection_without_expression(x) }
        elsif eager_limiting_select_statement?(o)
          groups = projections.map { |x| projection_without_expression(x) }
          projections = projections.map { |x| projection_without_expression(x) }
          orders = orders.map do |x|
            expr = Arel.sql projection_without_expression(x.expr)
            x.descending? ? Arel::Nodes::Max.new([expr]) : Arel::Nodes::Min.new([expr])
          end
        end
        [ ("SELECT" if !windowed),
          (visit(o.limit) if o.limit && !windowed),
          (projections.map{ |x| visit(x) }.join(', ')),
          (source_with_lock_for_select_statement(o)),
          ("WHERE #{core.wheres.map{ |x| visit(x) }.join ' AND ' }" unless core.wheres.empty?),
          ("GROUP BY #{groups.map { |x| visit x }.join ', ' }" unless groups.empty?),
          (visit(core.having) if core.having),
          ("ORDER BY #{orders.map{ |x| visit(x) }.join(', ')}" if !orders.empty? && !windowed)
        ].compact.join ' '
      end

      def visit_Arel_Nodes_SelectStatementWithOffset(o)
        orders = rowtable_orders(o)
        [ "SELECT",
          (visit(o.limit) if o.limit && !single_distinct_select_statement?(o)),
          (rowtable_projections(o).map{ |x| visit(x) }.join(', ')),
          "FROM (",
            "SELECT ROW_NUMBER() OVER (ORDER BY #{orders.map{ |x| visit(x) }.join(', ')}) AS [__rn],",
            visit_Arel_Nodes_SelectStatementWithOutOffset(o,true),
          ") AS [__rnt]",
          (visit(o.offset) if o.offset),
        ].compact.join ' '
      end

      def visit_Arel_Nodes_SelectStatementForComplexCount(o)
        core = o.cores.first
        o.limit.expr = Arel.sql("#{o.limit.expr} + #{o.offset ? o.offset.expr : 0}") if o.limit
        orders = rowtable_orders(o)
        [ "SELECT COUNT([count]) AS [count_id]",
          "FROM (",
            "SELECT",
            (visit(o.limit) if o.limit),
            "ROW_NUMBER() OVER (ORDER BY #{orders.map{ |x| visit(x) }.join(', ')}) AS [__rn],",
            "1 AS [count]",
            (source_with_lock_for_select_statement(o)),
            ("WHERE #{core.wheres.map{ |x| visit(x) }.join ' AND ' }" unless core.wheres.empty?),
            ("GROUP BY #{core.groups.map { |x| visit x }.join ', ' }" unless core.groups.empty?),
            (visit(core.having) if core.having),
            ("ORDER BY #{o.orders.map{ |x| visit(x) }.join(', ')}" if !o.orders.empty?),
          ") AS [__rnt]",
          (visit(o.offset) if o.offset)
        ].compact.join ' '
      end


      # SQLServer Helpers

      def source_with_lock_for_select_statement(o)
        # TODO: [ARel 2.2] Use #from/#source vs. #froms
        core = o.cores.first
        source = "FROM #{visit core.froms}" if core.froms
        if source && o.lock
          lock = visit o.lock
          index = source.match(/FROM [\w\[\]\.]+/)[0].length
          source.insert index, " #{lock}"
        else
          source
        end
      end

      def table_from_select_statement(o)
        core = o.cores.first
        # TODO: [ARel 2.2] Use #from/#source vs. #froms
        # if Arel::Table === core.from
        #   core.from
        # elsif Arel::Nodes::SqlLiteral === core.from
        #   Arel::Table.new(core.from, @engine)
        # elsif Arel::Nodes::JoinSource === core.source
        #   Arel::Nodes::SqlLiteral === core.source.left ? Arel::Table.new(core.source.left, @engine) : core.source.left
        # end
        table_finder = lambda { |x|
          case x
          when Arel::Table
            x
          when Arel::Nodes::SqlLiteral
            Arel::Table.new(x, @engine)
          when Arel::Nodes::Join
            table_finder.call(x.left)
          end
        }
        table_finder.call(core.froms)
      end

      def single_distinct_select_statement?(o)
        projections = o.cores.first.projections
        p1 = projections.first
        projections.size == 1 &&
          ((p1.respond_to?(:distinct) && p1.distinct) ||
            p1.respond_to?(:include?) && p1.include?('DISTINCT'))
      end

      def all_projections_aliased_in_select_statement?(o)
        projections = o.cores.first.projections
        projections.all? do |x|
          x.split(',').all? { |y| y.include?(' AS ') }
        end
      end

      def function_select_statement?(o)
        core = o.cores.first
        core.projections.any? { |x| Arel::Nodes::Function === x }
      end

      def eager_limiting_select_statement?(o)
        core = o.cores.first
        single_distinct_select_statement?(o) && (o.limit && !o.offset) && core.groups.empty?
      end

      def join_in_select_statement?(o)
        core = o.cores.first
        # TODO: [ARel 2.2] Use #from/#source vs. #froms
        # core.source.right.any? { |x| Arel::Nodes::Join === x }
        Arel::Nodes::Join === core.froms
      end

      def complex_count_sql?(o)
        core = o.cores.first
        core.projections.size == 1 &&
          Arel::Nodes::Count === core.projections.first &&
          (o.limit || !core.wheres.empty?) &&
          !join_in_select_statement?(o)
      end

      def find_and_fix_uncorrelated_joins_in_select_statement(o)
        core = o.cores.first
        # TODO: [ARel 2.2] Use #from/#source vs. #froms
        # return if !join_in_select_statement?(o) || core.source.right.size != 2
        # j1 = core.source.right.first
        # j2 = core.source.right.second
        # return unless Arel::Nodes::OuterJoin === j1 && Arel::Nodes::StringJoin === j2
        # j1_tn = j1.left.name
        # j2_tn = j2.left.match(/JOIN \[(.*)\].*ON/).try(:[],1)
        # return unless j1_tn == j2_tn
        # crltd_tn = "#{j1_tn}_crltd"
        # j1.left.table_alias = crltd_tn
        # j1.right.expr.left.relation.table_alias = crltd_tn
        return if !join_in_select_statement?(o) || !(Arel::Nodes::StringJoin === core.froms)
        j1 = core.froms.left
        j2 = core.froms.right
        return unless Arel::Nodes::OuterJoin === j1 && Arel::Nodes::SqlLiteral === j2 && j2.include?('JOIN ')
        j1_tn = j1.right.name
        j2_tn = j2.match(/JOIN \[(.*)\].*ON/).try(:[],1)
        return unless j1_tn == j2_tn
        on_index = j2.index(' ON ')
        j2.insert on_index, " AS [#{j2_tn}_crltd]"
        j2.sub! "[#{j2_tn}].", "[#{j2_tn}_crltd]."
      end

      def rowtable_projections(o)
        core = o.cores.first
        if single_distinct_select_statement?(o)
          tn = table_from_select_statement(o).name
          core.projections.map do |x|
            x.dup.tap do |p|
              p.sub! 'DISTINCT', "DISTINCT #{visit(o.limit)}".strip if o.limit
              p.sub! /\[#{tn}\]\./, '[__rnt].'
              p.strip!
            end
          end
        elsif join_in_select_statement?(o) && all_projections_aliased_in_select_statement?(o)
          core.projections.map do |x|
            Arel.sql x.split(',').map{ |y| y.split(' AS ').last.strip }.join(', ')
          end
        elsif function_select_statement?(o)
          # TODO: [ARel 2.2] Use Arel.star
          [Arel.sql('*')]
        else
          tn = table_from_select_statement(o).name
          core.projections.map { |x| x.gsub /\[#{tn}\]\./, '[__rnt].' }
        end
      end

      def rowtable_orders(o)
        core = o.cores.first
        if !o.orders.empty?
          o.orders
        else
          t = table_from_select_statement(o)
          c = t.primary_key || t.columns.first
          [c.asc]
        end.uniq
      end

      # TODO: We use this for grouping too, maybe make Grouping objects vs SqlLiteral.
      def projection_without_expression(projection)
        Arel.sql(projection.split(',').map do |x|
          x.strip!
          x.sub!(/^(COUNT|SUM|MAX|MIN|AVG)\s*(\((.*)\))?/,'\3')
          x.sub!(/^DISTINCT\s*/,'')
          x.sub!(/TOP\s*\(\d+\)\s*/i,'')
          x.strip
        end.join(', '))
      end

    end
  end

end

Arel::Visitors::VISITORS['sqlserver'] = Arel::Visitors::SQLServer
