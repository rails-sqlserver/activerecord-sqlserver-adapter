# frozen_string_literal: true

require "active_record/connection_adapters/sqlserver/showplan/printer_table"
require "active_record/connection_adapters/sqlserver/showplan/printer_xml"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Showplan
        OPTION_ALL  = "SHOWPLAN_ALL"
        OPTION_TEXT = "SHOWPLAN_TEXT"
        OPTION_XML  = "SHOWPLAN_XML"
        OPTIONS = [OPTION_ALL, OPTION_TEXT, OPTION_XML]

        def explain(arel, binds = [], options = [])
          sql = to_sql(arel)
          result = with_showplan_on { internal_exec_query(sql, "EXPLAIN", binds) }
          printer = showplan_printer.new(result)
          printer.pp
        end

        protected

        def with_showplan_on
          set_showplan_option(true)
          yield
        ensure
          set_showplan_option(false)
        end

        def set_showplan_option(enable = true)
          sql = "SET #{showplan_option} #{enable ? 'ON' : 'OFF'}"
          raw_execute(sql, "SCHEMA")
        rescue Exception
          raise ActiveRecordError, "#{showplan_option} could not be turned #{enable ? 'ON' : 'OFF'}, perhaps you do not have SHOWPLAN permissions?"
        end

        def showplan_option
          (SQLServerAdapter.showplan_option || OPTION_ALL).tap do |opt|
            raise(ArgumentError, "Unknown SHOWPLAN option #{opt.inspect} found.") if OPTIONS.exclude?(opt)
          end
        end

        def showplan_all?
          showplan_option == OPTION_ALL
        end

        def showplan_text?
          showplan_option == OPTION_TEXT
        end

        def showplan_xml?
          showplan_option == OPTION_XML
        end

        def showplan_printer
          case showplan_option
          when OPTION_XML then PrinterXml
          when OPTION_ALL, OPTION_TEXT then PrinterTable
          else PrinterTable
          end
        end
      end
    end
  end
end
