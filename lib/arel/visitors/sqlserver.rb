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

      def bind_block; BIND_BLOCK; end

      def visit_Arel_Nodes_Bin(o, collector)
        visit o.expr, collector
        collector << " #{ActiveRecord::ConnectionAdapters::SQLServerAdapter.cs_equality_operator} "
      end

      def visit_Arel_Nodes_Concat(o, collector)
        visit o.left, collector
        collector << " + "
        visit o.right, collector
      end

      def visit_Arel_Nodes_UpdateStatement(o, collector)
        if o.orders.any? && o.limit.nil?
          o.limit = Nodes::Limit.new(9_223_372_036_854_775_807)
        end
        super
      end

      def visit_Arel_Nodes_Lock(o, collector)
        o.expr = Arel.sql("WITH(UPDLOCK)") if o.expr.to_s =~ /FOR UPDATE/
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
          collector << ROWS_ONLY
        else
          collector << FETCH
          visit o.expr, collector
          collector << ROWS_ONLY
        end
      end

      def visit_Arel_Nodes_Grouping(o, collector)
        remove_invalid_ordering_from_select_statement(o.expr)
        super
      end

      def visit_Arel_Nodes_HomogeneousIn(o, collector)
        collector.preparable = false

        visit o.left, collector

        if o.type == :in
          collector << " IN ("
        else
          collector << " NOT IN ("
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
        distinct_One_As_One_Is_So_Not_Fetch o
        if o.with
          collector = visit o.with, collector
          collector << " "
        end
        collector = o.cores.inject(collector) { |c, x|
          visit_Arel_Nodes_SelectCore(x, c)
        }
        collector = visit_Orders_And_Let_Fetch_Happen o, collector
        collector = visit_Make_Fetch_Happen o, collector
        collector
      ensure
        @select_statement = nil
      end

      def visit_Arel_Nodes_SelectCore(o, collector)
        collector = super
        maybe_visit o.optimizer_hints, collector
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
            if o.class.engine.connection.respond_to?(:sqlserver?) && o.class.engine.connection.database_prefix_remote_server?
              remote_server_table_name(o)
            else
              quote_table_name(o.name)
            end
          rescue Exception
            quote_table_name(o.name)
          end

        if o.table_alias
          collector << "#{table_name} #{quote_table_name o.table_alias}"
        else
          collector << table_name
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
        unless o.orders.empty?
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
        @select_statement && @select_statement.lock
      end

      def make_Fetch_Possible_And_Deterministic(o)
        return if o.limit.nil? && o.offset.nil?

        t = table_From_Statement o
        pk = primary_Key_From_Table t
        return unless pk

        if o.orders.empty?
          # Prefer deterministic vs a simple `(SELECT NULL)` expr.
          o.orders = [pk.asc]
        end
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
          Arel::Nodes::SqlLiteral === core.source.left ? Arel::Table.new(core.source.left, @engine) : core.source.left.left
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
        ActiveRecord::ConnectionAdapters::SQLServer::Utils.extract_identifiers(
          "#{o.class.engine.connection.database_prefix}#{o.name}"
        ).quoted
      end

      # Need to remove ordering from subqueries unless TOP/OFFSET also used. Otherwise, SQLServer
      # returns error "The ORDER BY clause is invalid in views, inline functions, derived tables,
      # subqueries, and common table expressions, unless TOP, OFFSET or FOR XML is also specified."
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
