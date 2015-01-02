require 'strscan'

module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module Utils

        # Value object to return identifiers from SQL Server names http://bit.ly/1CZ3EiL
        # Inspiried from Rails PostgreSQL::Name adapter object in their own Utils.
        #
        class Name

          SEPARATOR = "."
          SCANNER   = /\]?\./

          attr_reader :server, :database, :schema, :object
          attr_reader :raw_name

          def initialize(name)
            @raw_name = name.to_s
            parse_raw_name
          end

          def object_quoted
            quote object
          end

          def schema_quoted
            schema ? quote(schema) : schema
          end

          def database_quoted
            database ? quote(database) : database
          end

          def server_quoted
            server ? quote(server) : server
          end

          def to_s
            quoted
          end

          def quoted
            parts.map{ |p| quote(p) if p }.join SEPARATOR
          end

          def ==(o)
            o.class == self.class && o.parts == parts
          end
          alias_method :eql?, :==

          def hash
            parts.hash
          end

          protected

          def parse_raw_name
            @parts = []
            return if raw_name.blank?
            scanner = StringScanner.new(raw_name)
            matched = scanner.scan_until(SCANNER)
            while matched
              part = matched[0..-2]
              @parts << (part.blank? ? nil : unquote(part))
              matched = scanner.scan_until(SCANNER)
            end
            case @parts.length
            when 3
              @server, @database, @schema = @parts
            when 2
              @database, @schema = @parts
            when 1
              @schema = @parts.first
            end
            rest = scanner.rest
            rest = rest.starts_with?('.') ? rest[1..-1] : rest[0..-1]
            @object = unquote(rest)
            @parts << @object
          end

          def quote(part)
            part =~ /\A\[.*\]\z/ ? part : "[#{part.to_s.gsub(']', ']]')}]"
          end

          def unquote(part)
            if part && part.start_with?('[')
              part[1..-2]
            else
              part
            end
          end

          def parts
            @parts
          end

        end

        extend self

        def quote_string(s)
          s.gsub /\'/, "''"
        end

        def unquote_string(s)
          s.to_s.gsub(/\'\'/, "'")
        end

        def extract_identifiers(name)
          Sqlserver::Utils::Name.new(name)
        end

      end
    end
  end
end
