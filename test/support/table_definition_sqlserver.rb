# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class TableDefinition < ::ActiveRecord::ConnectionAdapters::TableDefinition
        # SQL Server supports precision of 38 for decimal columns. In Rails the test schema includes a column
        # with a precision of 55. This is a problem for SQL Server 2008. This method will override the default
        # decimal method to limit the precision to 38 for the :atoms_in_universe column.
        # See https://github.com/rails/rails/pull/51826/files#diff-2a57b61bbf9ee2c23938fc571d403799f68b4b530d65e2cde219a429bbf10af5L876
        def decimal(*names, **options)
          throw "This 'decimal' method should only be used in a test environment." unless defined?(ActiveSupport::TestCase)

          names.each do |name|
            options_for_name = options.dup
            options_for_name[:precision] = 38 if name == :atoms_in_universe && options_for_name[:precision].to_i == 55

            column(name, :decimal, **options_for_name)
          end
        end
      end
    end
  end
end
