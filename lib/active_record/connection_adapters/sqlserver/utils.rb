module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      class Utils
        
        class << self
          
          def unquote_string(string)
            string.to_s.gsub(/\'\'/, "'")
          end
          
          def unqualify_table_name(table_name)
            table_name.to_s.split('.').last.tr('[]','')
          end

          def unqualify_table_schema(table_name)
            table_name.to_s.split('.')[-2].gsub(/[\[\]]/,'') rescue nil
          end

          def unqualify_db_name(table_name)
            table_names = table_name.to_s.split('.')
            table_names.length == 3 ? table_names.first.tr('[]','') : nil
          end
          
        end
        
      end
    end
  end
end


