# frozen_string_literal: true

module Arel
  module Visitors
    class SQLServer < Arel::Visitors::ToSql
      OFFSET = " OFFSET "
      ROWS = " ROWS"
      FETCH = " FETCH NEXT "
      FETCH0 = " FETCH FIRST (SELECT 0) "
      ROWS_ONLY = " ROWS ONLY"

      private

      # SQLServer ToSql/Visitor (Overrides)

      BIND_BLOCK = proc { |i| "@#{i - 1}" }
      private_constant :BIND_BLOCK

      def bind_block
        BIND_BLOCK
      end

      def visit_Arel_Nodes_Bin(o, collector)
        visit o.expr, collector
        collector << " #{ActiveRecord::ConnectionAdapters::SQLServerAdapter.cs_equality_operator} "
      end

      def visit_Arel_Nodes_Concat(o, collector)
        visit o.left, collector
        collector << " + "
        visit o.right, collector
      end

      # Same as SQLite and PostgreSQL.
      def visit_Arel_Nodes_UpdateStatement(o, collector)
        collector.retryable = false
        o = prepare_update_statement(o)

        collector << "UPDATE "

        # UPDATE with JOIN is in the form of:
        #
        #   UPDATE t1
        #   SET ..
        #   FROM t1 JOIN t2 ON t2.join_id = t1.join_id ..
        #   WHERE ..
        if has_join_sources?(o)
          collector = visit o.relation.left, collector
          collect_nodes_for o.values, collector, " SET "
          collector << " FROM "
          collector = inject_join o.relation.right, collector, " "
        else
          collector = visit o.relation, collector
          collect_nodes_for o.values, collector, " SET "
        end

        collect_nodes_for o.wheres, collector, " WHERE ", " AND "
        collect_nodes_for o.orders, collector, " ORDER BY "
        maybe_visit o.limit, collector
        maybe_visit o.comment, collector
      end

      # Similar to PostgreSQL and SQLite.
      def prepare_update_statement(o)
        if o.key && has_join_sources?(o) && !has_group_by_and_having?(o) && !has_limit_or_offset_or_orders?(o)
          # Join clauses cannot reference the target table, so alias the
          # updated table, place the entire relation in the FROM clause, and
          # add a self-join (which requires the primary key)
          stmt = o.clone

          stmt.relation, stmt.wheres = o.relation.clone, o.wheres.clone
          stmt.relation.right = [stmt.relation.left, *stmt.relation.right]
          # Don't need to use alias
          stmt
        else
          # If using subquery, we need to add limit
          o.limit = Nodes::Limit.new(9_223_372_036_854_775_807) if o.orders.any? && o.limit.nil?

          super
        end
      end

      def visit_Arel_Nodes_DeleteStatement(o, collector)
        if has_join_and_composite_primary_key?(o)
          delete_statement_using_join(o, collector)
        else
          super
        end
      end

      def has_join_and_composite_primary_key?(o)
        has_join_sources?(o) && o.relation.left.instance_variable_get(:@klass).composite_primary_key?
      end

      def delete_statement_using_join(o, collector)
        collector.retryable = false

        collector << "DELETE "
        visit o.relation.left, collector
        collector << " FROM "
        visit o.relation, collector
        collect_nodes_for o.wheres, collector, " WHERE ", " AND "
      end

      def visit_Arel_Nodes_Lock(o, collector)
        o.expr = Arel.sql("WITH(UPDLOCK)") if /FOR UPDATE/.match?(o.expr.to_s)
        collector << " "
        visit o.expr, collector
      end

      def visit_Arel_Nodes_Offset(o, collector)
        collector << OFFSET
        visit o.expr, collector
        collector << ROWS
      end

      def visit_Arel_Nodes_Limit(o, collector)
        if node_value(o) == 0
          collector << FETCH0
        else
          collector << FETCH
          visit o.expr, collector
        end
        collector << ROWS_ONLY
      end

      def visit_Arel_Nodes_Grouping(o, collector)
        remove_invalid_ordering_from_select_statement(o.expr)
        super
      end

      def visit_Arel_Nodes_HomogeneousIn(o, collector)
        collector.preparable = false

        visit o.left, collector

        collector << if o.type == :in
          " IN ("
        else
          " NOT IN ("
        end

        values = o.casted_values

        # Monkey-patch start.
        column_name = o.attribute.name
        column_type = o.attribute.relation.type_for_attribute(column_name)
        column_type = column_type.cast_type if column_type.is_a?(ActiveRecord::Encryption::EncryptedAttributeType) # Use cast_type on encrypted attributes. Don't encrypt them again

        if values.empty?
          collector << @connection.quote(nil)
        elsif @connection.prepared_statements && !column_type.serialized?
          # Add query attribute bindings rather than just values.
          attrs = values.map { |value| ActiveRecord::Relation::QueryAttribute.new(column_name, value, column_type) }
          collector.add_binds(attrs, &bind_block)
        else
          collector.add_binds(values, o.proc_for_binds, &bind_block)
        end
        # Monkey-patch end.

        collector << ")"
      end

      def visit_Arel_Nodes_SelectStatement(o, collector)
        @select_statement = o
        optimizer_hints = nil
        distinct_One_As_One_Is_So_Not_Fetch o
        if o.with
          collector = visit o.with, collector
          collector << " "
        end
        collector = o.cores.inject(collector) do |collect, core|
          optimizer_hints = core.optimizer_hints if core.optimizer_hints
          visit_Arel_Nodes_SelectCore(core, collect)
        end
        collector = visit_Orders_And_Let_Fetch_Happen o, collector
        collector = visit_Make_Fetch_Happen o, collector
        collector = maybe_visit optimizer_hints, collector
        collector
      ensure
        @select_statement = nil
      end

      def visit_Arel_Nodes_OptimizerHints(o, collector)
        hints = o.expr.map { |v| sanitize_as_option_clause(v) }.join(", ")
        collector << "OPTION (#{hints})"
      end

      def visit_Arel_Table(o, collector)
        # Apparently, o.engine.connection can actually be a different adapter
        # than sqlserver. Can be removed if fixed in ActiveRecord. See:
        # github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/450
        table_name =
          begin
            o.class.engine.with_connection do |connection|
              if connection.respond_to?(:sqlserver?) && connection.database_prefix_remote_server?
                remote_server_table_name(o)
              else
                quote_table_name(o.name)
              end
            end
          rescue
            quote_table_name(o.name)
          end

        collector << if o.table_alias
          "#{table_name} #{quote_table_name o.table_alias}"
        else
          table_name
        end
      end

      def visit_Arel_Nodes_JoinSource(o, collector)
        if o.left
          collector = visit o.left, collector
          collector = visit_Arel_Nodes_SelectStatement_SQLServer_Lock collector
        end
        if o.right.any?
          collector << " " if o.left
          collector = inject_join o.right, collector, " "
        end
        collector
      end

      def visit_Arel_Nodes_InnerJoin(o, collector)
        if o.left.is_a?(Arel::Nodes::As) && o.left.left.is_a?(Arel::Nodes::Lateral)
          collector << "CROSS "
          visit o.left, collector
        else
          collector << "INNER JOIN "
          collector = visit o.left, collector
          collector = visit_Arel_Nodes_SelectStatement_SQLServer_Lock collector, space: true
          if o.right
            collector << " "
            visit(o.right, collector)
          else
            collector
          end
        end
      end

      def visit_Arel_Nodes_OuterJoin(o, collector)
        if o.left.is_a?(Arel::Nodes::As) && o.left.left.is_a?(Arel::Nodes::Lateral)
          collector << "OUTER "
          visit o.left, collector
        else
          collector << "LEFT OUTER JOIN "
          collector = visit o.left, collector
          collector = visit_Arel_Nodes_SelectStatement_SQLServer_Lock collector, space: true
          collector << " "
          visit o.right, collector
        end
      end

      def visit_Arel_Nodes_In(o, collector)
        if Array === o.right
          o.right.each { |node| remove_invalid_ordering_from_select_statement(node) }
        else
          remove_invalid_ordering_from_select_statement(o.right)
        end

        super
      end

      def collect_optimizer_hints(o, collector)
        collector
      end

      def visit_Arel_Nodes_WithRecursive(o, collector)
        collector << "WITH "
        collect_ctes(o.children, collector)
      end

      # SQLServer ToSql/Visitor (Additions)

      def visit_Arel_Nodes_SelectStatement_SQLServer_Lock(collector, options = {})
        if select_statement_lock?
          collector = visit @select_statement.lock, collector
          collector << " " if options[:space]
        end
        collector
      end

      def visit_Orders_And_Let_Fetch_Happen(o, collector)
        make_Fetch_Possible_And_Deterministic o
        if o.orders.any?
          collector << " ORDER BY "
          len = o.orders.length - 1
          o.orders.each_with_index { |x, i|
            collector = visit(x, collector)
            collector << ", " unless len == i
          }
        end
        collector
      end

      def visit_Make_Fetch_Happen(o, collector)
        o.offset = Nodes::Offset.new(0) if o.limit && !o.offset
        collector = visit o.offset, collector if o.offset
        collector = visit o.limit, collector if o.limit
        collector
      end

      def visit_Arel_Nodes_Lateral(o, collector)
        collector << "APPLY"
        collector << " "
        if o.expr.is_a?(Arel::Nodes::SelectStatement)
          collector << "("
          visit(o.expr, collector)
          collector << ")"
        else
          visit(o.expr, collector)
        end
      end

      # SQLServer Helpers

      def node_value(node)
        return nil unless node

        case node.expr
        when NilClass then nil
        when Numeric then node.expr
        when Arel::Nodes::Unary then node.expr.expr
        end
      end

      def select_statement_lock?
        @select_statement&.lock
      end

      def make_Fetch_Possible_And_Deterministic(o)
        return if o.limit.nil? && o.offset.nil?
        return if o.orders.any?

        t = table_From_Statement o
        pk = primary_Key_From_Table t
        return unless pk

        # Prefer deterministic vs a simple `(SELECT NULL)` expr.
        o.orders = [pk.asc]
      end

      def distinct_One_As_One_Is_So_Not_Fetch(o)
        core = o.cores.first
        distinct = Nodes::Distinct === core.set_quantifier
        oneasone = core.projections.all? { |x| x == ActiveRecord::FinderMethods::ONE_AS_ONE }
        limitone = [nil, 0, 1].include? node_value(o.limit)
        if distinct && oneasone && limitone && !o.offset
          core.projections = [Arel.sql("TOP(1) 1 AS [one]")]
          o.limit = nil
        end
      end

      def table_From_Statement(o)
        core = o.cores.first
        if Arel::Table === core.from
          core.from
        elsif Arel::Nodes::SqlLiteral === core.from
          Arel::Table.new(core.from)
        elsif Arel::Nodes::JoinSource === core.source
          (Arel::Nodes::SqlLiteral === core.source.left) ? Arel::Table.new(core.source.left, @engine) : core.source.left.left
        end
      end

      def primary_Key_From_Table(t)
        return unless t

        primary_keys = @connection.schema_cache.primary_keys(t.name)
        column_name = nil

        case primary_keys
        when NilClass
          column_name = @connection.schema_cache.columns_hash(t.name).first.try(:second).try(:name)
        when String
          column_name = primary_keys
        when Array
          candidate_columns = @connection.schema_cache.columns_hash(t.name).slice(*primary_keys).values
          candidate_column = candidate_columns.find(&:is_identity?)
          candidate_column ||= candidate_columns.first
          column_name = candidate_column.try(:name)
        end

        column_name ? t[column_name] : nil
      end

      def remote_server_table_name(o)
        o.class.engine.with_connection do |connection|
          ActiveRecord::ConnectionAdapters::SQLServer::Utils.extract_identifiers(
            "#{connection.database_prefix}#{o.name}"
          ).quoted
        end
      end

      # Need to remove ordering from sub-queries unless TOP/OFFSET also used. Otherwise, SQLServer
      # returns error "The ORDER BY clause is invalid in views, inline functions, derived tables,
      # sub-queries, and common table expressions, unless TOP, OFFSET or FOR XML is also specified."
      def remove_invalid_ordering_from_select_statement(node)
        return unless Arel::Nodes::SelectStatement === node

        node.orders = [] unless node.offset || node.limit
      end

      def sanitize_as_option_clause(value)
        value.gsub(%r{OPTION \s* \( (.+) \)}xi, "\\1")
      end
    end
  end
end
