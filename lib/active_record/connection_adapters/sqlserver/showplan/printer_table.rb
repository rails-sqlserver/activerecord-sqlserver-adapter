module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Showplan
        class PrinterTable
          cattr_accessor :max_column_width, :cell_padding
          self.max_column_width = 50
          self.cell_padding = 1

          attr_reader :result

          def initialize(result)
            @result = result
          end

          def pp
            @widths = compute_column_widths
            @separator = build_separator
            pp = []
            pp << @separator
            pp << build_cells(result.columns)
            pp << @separator
            result.rows.each do |row|
              pp << build_cells(row)
            end
            pp << @separator
            pp.join("\n") + "\n"
          end

          private

          def compute_column_widths
            [].tap do |computed_widths|
              result.columns.each_with_index do |column, i|
                cells_in_column = [column] + result.rows.map { |r| cast_item(r[i]) }
                computed_width = cells_in_column.map(&:length).max
                final_width = computed_width > max_column_width ? max_column_width : computed_width
                computed_widths << final_width
              end
            end
          end

          def build_separator
            '+' + @widths.map { |w| '-' * (w + (cell_padding * 2)) }.join('+') + '+'
          end

          def build_cells(items)
            cells = []
            items.each_with_index do |item, i|
              cells << cast_item(item).ljust(@widths[i])
            end
            "| #{cells.join(' | ')} |"
          end

          def cast_item(item)
            case item
            when NilClass then 'NULL'
            when Float then item.to_s.to(9)
            else item.to_s.truncate(max_column_width)
            end
          end
        end
      end
    end
  end
end
