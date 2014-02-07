module Arel
  module Visitors
    class SQLServer < Arel::Visitors::ToSql

      private

      # SQLServer ToSql/Visitor (Overides)

      def visit_Arel_Nodes_SelectStatement(o, a)
        if complex_count_sql?(o)
          visit_Arel_Nodes_SelectStatementForComplexCount(o, a)
        elsif o.offset
          visit_Arel_Nodes_SelectStatementWithOffset(o, a)
        else
          visit_Arel_Nodes_SelectStatementWithOutOffset(o, a)
        end
      end

      def visit_Arel_Nodes_UpdateStatement(o, a)
        if o.orders.any? && o.limit.nil?
          o.limit = Nodes::Limit.new(9223372036854775807)
        end
        super
      end

      def visit_Arel_Nodes_Offset(o, a)
        "WHERE [__rnt].[__rn] > (#{visit o.expr, a})"
      end

      def visit_Arel_Nodes_Limit(o, a)
        "TOP (#{visit o.expr, a})"
      end

      def visit_Arel_Nodes_Lock(o, a)
        visit o.expr, a
      end

      def visit_Arel_Nodes_Ordering(o, a)
        if o.respond_to?(:direction)
          "#{visit o.expr, a} #{o.ascending? ? 'ASC' : 'DESC'}"
        else
          visit o.expr, a
        end
      end

      def visit_Arel_Nodes_Bin(o, a)
        "#{visit o.expr, a} #{@connection.cs_equality_operator}"
      end

      # SQLServer ToSql/Visitor (Additions)

      def visit_Arel_Nodes_SelectStatementWithOutOffset(o, a, windowed = false)
        find_and_fix_uncorrelated_joins_in_select_statement(o)
        core = o.cores.first
        projections = core.projections
        groups = core.groups
        orders = o.orders.uniq
        if windowed
          projections = function_select_statement?(o) ? projections : projections.map { |x| projection_without_expression(x, a) }
          groups = projections.map { |x| projection_without_expression(x, a) } if windowed_single_distinct_select_statement?(o) && groups.empty?
          groups += orders.map { |x| Arel.sql(x.expr) } if windowed_single_distinct_select_statement?(o)
        elsif eager_limiting_select_statement?(o, a)
          projections = projections.map { |x| projection_without_expression(x, a) }
          groups = projections.map { |x| projection_without_expression(x, a) }
          orders = orders.map do |x|
            expr = Arel.sql projection_without_expression(x.expr, a)
            x.descending? ? Arel::Nodes::Max.new([expr]) : Arel::Nodes::Min.new([expr])
          end
        elsif top_one_everything_for_through_join?(o, a)
          projections = projections.map { |x| projection_without_expression(x, a) }
        end
        [ ("SELECT" if !windowed),
          (visit(core.set_quantifier, a) if core.set_quantifier && !windowed),
          (visit(o.limit, a) if o.limit && !windowed),
          (projections.map{ |x| v = visit(x, a); v == "1" ? "1 AS [__wrp]" : v }.join(', ')),
          (source_with_lock_for_select_statement(o, a)),
          ("WHERE #{core.wheres.map{ |x| visit(x, a) }.join ' AND ' }" unless core.wheres.empty?),
          ("GROUP BY #{groups.map { |x| visit(x, a) }.join ', ' }" unless groups.empty?),
          (visit(core.having, a) if core.having),
          ("ORDER BY #{orders.map{ |x| visit(x, a) }.join(', ')}" if !orders.empty? && !windowed)
        ].compact.join ' '
      end

      def visit_Arel_Nodes_SelectStatementWithOffset(o, a)
        core = o.cores.first
        o.limit ||= Arel::Nodes::Limit.new(9223372036854775807)
        orders = rowtable_orders(o)
        [ "SELECT",
          (visit(o.limit, a) if o.limit && !windowed_single_distinct_select_statement?(o)),
          (rowtable_projections(o, a).map{ |x| visit(x, a) }.join(', ')),
          "FROM (",
            "SELECT #{core.set_quantifier ? 'DISTINCT DENSE_RANK()' : 'ROW_NUMBER()'} OVER (ORDER BY #{orders.map{ |x| visit(x, a) }.join(', ')}) AS [__rn],",
            visit_Arel_Nodes_SelectStatementWithOutOffset(o, a, true),
          ") AS [__rnt]",
          (visit(o.offset, a) if o.offset),
          "ORDER BY [__rnt].[__rn] ASC"
        ].compact.join ' '
      end

      def visit_Arel_Nodes_SelectStatementForComplexCount(o, a)
        core = o.cores.first
        o.limit.expr = Arel.sql("#{o.limit.expr} + #{o.offset ? o.offset.expr : 0}") if o.limit
        orders = rowtable_orders(o)
        [ "SELECT COUNT([count]) AS [count_id]",
          "FROM (",
            "SELECT",
            (visit(o.limit, a) if o.limit),
            "ROW_NUMBER() OVER (ORDER BY #{orders.map{ |x| visit(x, a) }.join(', ')}) AS [__rn],",
            "1 AS [count]",
            (source_with_lock_for_select_statement(o, a)),
            ("WHERE #{core.wheres.map{ |x| visit(x, a) }.join ' AND ' }" unless core.wheres.empty?),
            ("GROUP BY #{core.groups.map { |x| visit(x, a) }.join ', ' }" unless core.groups.empty?),
            (visit(core.having, a) if core.having),
            ("ORDER BY #{o.orders.map{ |x| visit(x, a) }.join(', ')}" if !o.orders.empty?),
          ") AS [__rnt]",
          (visit(o.offset, a) if o.offset)
        ].compact.join ' '
      end


      # SQLServer Helpers

      def source_with_lock_for_select_statement(o, a)
        core = o.cores.first
        source = "FROM #{visit(core.source, a).strip}" if core.source
        if source && o.lock
          lock = visit o.lock, a
          index = source.match(/FROM [\w\[\]\.]+/)[0].mb_chars.length
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

      def windowed_single_distinct_select_statement?(o)

        o.limit &&
          o.offset &&
          single_distinct_select_statement?(o)
      end

      def single_distinct_select_everything_statement?(o, a)
        single_distinct_select_statement?(o) &&
          visit(o.cores.first.projections.first, a).ends_with?(".*")
      end

      def top_one_everything_for_through_join?(o, a)
        single_distinct_select_everything_statement?(o, a) &&
          (o.limit && !o.offset) &&
          join_in_select_statement?(o)
      end

      def all_projections_aliased_in_select_statement?(o, a)
        projections = o.cores.first.projections
        projections.all? do |x|
          visit(x, a).split(',').all? { |y| y.include?(' AS ') }
        end
      end

      def function_select_statement?(o)
        core = o.cores.first
        core.projections.any? { |x| Arel::Nodes::Function === x }
      end

      def eager_limiting_select_statement?(o, a)
        core = o.cores.first
        single_distinct_select_statement?(o) &&
          (o.limit && !o.offset) &&
          core.groups.empty? &&
          !single_distinct_select_everything_statement?(o, a)
      end

      def join_in_select_statement?(o)
        core = o.cores.first
        core.source.right.any? { |x| Arel::Nodes::Join === x }
      end

      def complex_count_sql?(o)
        core = o.cores.first
        core.projections.size == 1 &&
          Arel::Nodes::Count === core.projections.first &&
          o.limit &&
          !join_in_select_statement?(o)
      end

      def select_primary_key_sql?(o)
        core = o.cores.first
        return false if core.projections.size != 1
        p = core.projections.first
        t = table_from_select_statement(o)
        Arel::Attributes::Attribute === p && t.primary_key && t.primary_key.name == p.name
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

      def rowtable_projections(o, a)
        core = o.cores.first
        if windowed_single_distinct_select_statement?(o) && core.groups.blank?
          tn = table_from_select_statement(o).name
          core.projections.map do |x|
            x.dup.tap do |p|
              p.sub! 'DISTINCT', ''
              p.insert 0, visit(o.limit, a) if o.limit
              p.gsub! /\[?#{tn}\]?\./, '[__rnt].'
              p.strip!
            end
          end
        elsif single_distinct_select_statement?(o)
          tn = table_from_select_statement(o).name
          core.projections.map do |x|
            x.dup.tap do |p|
              p.sub! 'DISTINCT', "DISTINCT #{visit(o.limit, a)}".strip if o.limit
              p.gsub! /\[?#{tn}\]?\./, '[__rnt].'
              p.strip!
            end
          end
        elsif join_in_select_statement?(o) && all_projections_aliased_in_select_statement?(o, a)
          core.projections.map do |x|
            Arel.sql visit(x, a).split(',').map{ |y| y.split(' AS ').last.strip }.join(', ')
          end
        elsif select_primary_key_sql?(o)
          [Arel.sql("[__rnt].#{quote_column_name(core.projections.first.name)}")]
        else
          [Arel.sql('[__rnt].*')]
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
      def projection_without_expression(projection, a)
        Arel.sql(visit(projection, a).split(',').map do |x|
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
