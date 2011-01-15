module Arel
  
  module Nodes
    
    class LockWithSQLServer < Arel::Nodes::Unary
    end
    
    class Limit < Arel::Nodes::Unary
      def initialize expr
        @expr = expr.to_i
      end
    end
    
    class Offset < Arel::Nodes::Unary
      def initialize expr
        @expr = expr.to_i
      end
    end
    
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
    
    def order(*exprs)
      @ast.orders.concat(exprs.map{ |x|
        case x
        when Arel::Attributes::Attribute
          c = engine.connection
          tn = x.relation.table_alias || x.relation.name
          expr = Nodes::SqlLiteral.new "#{c.quote_table_name(tn)}.#{c.quote_column_name(x.name)}"
          Nodes::Ordering.new expr
        when String
          x.split(',').map do |s|
            expr, direction = s.split
            expr = Nodes::SqlLiteral.new(expr)
            direction = direction =~ /desc/i ? :desc : :asc
            Nodes::Ordering.new expr, direction
          end
        else
          expr = Nodes::SqlLiteral.new x.to_s
          Nodes::Ordering.new expr
        end
      }.flatten)
      self
    end
    
    def lock(locking=true)
      if Arel::Visitors::SQLServer === @visitor
        @ast.lock = Nodes::LockWithSQLServer.new(locking)
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
        "WHERE [__rnt].[__rn] > #{visit o.expr}"
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
        orders = o.orders.reverse.uniq.reverse
        if windowed && !function_select_statement?(o)
          projections =  projections.map { |x| projection_without_expression(x) }
        elsif eager_limiting_select_statement?(o)
          raise "visit_Arel_Nodes_SelectStatementWithOutOffset - eager_limiting_select_statement?"
          groups = projections.map { |x| projection_without_expression(x) }
          projections = projections.map { |x| projection_without_expression(x) }
          # TODO: Let's alter objects vs strings and make new order objects
          orders = orders.map do |x|
            Arel::SqlLiteral.new(x.split(',').reject(&:blank?).map do |c|
              max = c =~ /desc\s*/i
              c = clause_without_expression(c).sub(/(asc|desc)/i,'').strip
              max ? "MAX(#{c})" : "MIN(#{c})"
            end.join(', '))
          end          
        end
        [ ("SELECT" if !windowed),
          (visit(o.limit) if o.limit && !windowed),
          (projections.map{ |x| visit(x) }.join(', ')),
          visit(core.source),
          (visit(o.lock) if o.lock),
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
        # joins   = correlated_safe_joins
        core = o.cores.first
        orders = rowtable_orders(o)
        o.limit.expr = o.limit.expr + (o.offset ? o.offset.expr : 0) if o.limit
        [ "SELECT COUNT([count]) AS [count_id]",
          "FROM (",
            "SELECT",
            (visit(o.limit) if o.limit),
            "ROW_NUMBER() OVER (ORDER BY #{orders.map{ |x| visit(x) }.join(', ')}) AS [__rn],",
            "1 AS [count]",
            visit(core.source),
            (visit(o.lock) if o.lock),
            ("WHERE #{core.wheres.map{ |x| visit(x) }.join ' AND ' }" unless core.wheres.empty?),
            ("GROUP BY #{core.groups.map { |x| visit x }.join ', ' }" unless core.groups.empty?),
            (visit(core.having) if core.having),
            ("ORDER BY #{o.orders.map{ |x| visit(x) }.join(', ')}" if !o.orders.empty?),
          ") AS [__rnt]",
          (visit(o.offset) if o.offset)
        ].compact.join ' '
      end
      
      
      # SQLServer Helpers
      
      def table_name_from_select_statement(o)
        o.cores.first.source.left.name
      end
      
      def single_distinct_select_statement?(o)
        projections = o.cores.first.projections
        first_prjn = projections.first
        projections.size == 1 && 
          ((first_prjn.respond_to?(:distinct) && first_prjn.distinct) || first_prjn.include?('DISTINCT'))
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
        core.source.right.any? { |x| Arel::Nodes::Join === x }
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
        return if !join_in_select_statement?(o) || core.source.right.size != 2
        j1 = core.source.right.first
        j2 = core.source.right.second
        return unless Arel::Nodes::OuterJoin === j1 && Arel::Nodes::StringJoin === j2
        j1_tn = j1.left.name
        j2_tn = j2.left.match(/JOIN \[(.*)\].*ON/).try(:[],1)
        return unless j1_tn == j2_tn
        crltd_tn = "#{j1_tn}_crltd"
        j1.left.table_alias = crltd_tn
        j1.right.expr.left.relation.table_alias = crltd_tn
      end
      
      def rowtable_projections(o)
        core = o.cores.first
        if single_distinct_select_statement?(o)
          raise 'TODO: single_distinct_select_statement'
          # ::Array.wrap(relation.select_clauses.first.dup.tap do |sc|
          #   sc.sub! 'DISTINCT', "DISTINCT #{taken_clause if relation.taken.present?}".strip
          #   sc.sub! table_name_from_select_clause(sc), '__rnt'
          #   sc.strip!
          # end)
        elsif false # relation.join? && all_select_clauses_aliased?
          raise 'TODO: relation.join? && all_select_clauses_aliased?'
          # relation.select_clauses.map do |sc|
          #   sc.split(',').map { |c| c.split(' AS ').last.strip  }.join(', ')
          # end
        elsif function_select_statement?(o)
          [Arel.star]
        else
          tn = table_name_from_select_statement(o)
          core.projections.map { |x| x.gsub /\[#{tn}\]\./, '[__rnt].' }
        end
      end
      
      def rowtable_orders(o)
        if !o.orders.empty?
          o.orders
        elsif false # TODO relation.join?
          # table_names_from_select_clauses.map { |tn| quote("#{tn}.#{pk_for_table(tn)}") }
        else
          tn = table_name_from_select_statement(o)
          [Arel::Table.new(tn, @engine).primary_key.asc]
        end.reverse.uniq.reverse
      end
      
      def projection_without_expression(projection)
        Arel::SqlLiteral.new(projection.split(',').map do |x|
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
