require 'strscan'

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Utils

        # Value object to return identifiers from SQL Server names http://bit.ly/1CZ3EiL
        # Inspiried from Rails PostgreSQL::Name adapter object in their own Utils.
        #
        class Name

          SEPARATOR = "."
          UNQUOTED_SCANNER = /\]?\./
          QUOTED_SCANNER   = /\A\[.*?\]\./
          QUOTED_CHECKER   = /\A\[/

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

          def fully_qualified_database_quoted
            [server_quoted, database_quoted].compact.join(SEPARATOR)
          end

          def fully_qualified?
            parts.compact.size == 4
          end

          def to_s
            quoted
          end

          def quoted
            parts.map{ |p| quote(p) if p }.join SEPARATOR
          end

          def quoted_raw
            quote @raw_name
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
            matched = scanner.exist?(QUOTED_CHECKER) ? scanner.scan_until(QUOTED_SCANNER) : scanner.scan_until(UNQUOTED_SCANNER)
            while matched
              part = matched[0..-2]
              @parts << (part.blank? ? nil : unquote(part))
              matched = scanner.exist?(QUOTED_CHECKER) ? scanner.scan_until(QUOTED_SCANNER) : scanner.scan_until(UNQUOTED_SCANNER)
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
          s.to_s.gsub /\'/, "''"
        end

        def quoted_raw(name)
          SQLServer::Utils::Name.new(name).quoted_raw
        end

        def unquote_string(s)
          s.to_s.gsub(/\'\'/, "'")
        end

        def extract_identifiers(name)
          SQLServer::Utils::Name.new(name)
        end

      end
    end
  end
end
