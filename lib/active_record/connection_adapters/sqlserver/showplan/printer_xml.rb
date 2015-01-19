module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Showplan
        class PrinterXml
          def initialize(result)
            @result = result
          end

          def pp
            xml = @result.rows.first.first
            if defined?(Nokogiri)
              Nokogiri::XML(xml).to_xml indent: 2, encoding: 'UTF-8'
            else
              xml
            end
          end
        end
      end
    end
  end
end
