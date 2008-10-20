require 'autotest'
require 'activesupport'

class Autotest::Sqlserveradapter < Autotest

  def initialize
    super
    
    odbc_mode = true
    
    clear_mappings
    
    self.libs = [
      "lib",
      "test",
      "test/connections/native_sqlserver#{odbc_mode ? '_odbc' : ''}",
      "../../../rails/activerecord/test/"
    ].join(File::PATH_SEPARATOR)
    
    self.extra_files = ['../../../rails/activerecord/test/']
    
    self.add_mapping %r%^test/.*/.*_test_sqlserver.rb$% do |filename, _|
      filename
    end
    
    self.add_mapping %r%../../../rails/activerecord/test/.*/.*_test.rb$% do |filename, _|
      filename
    end
    
  end
  
  # Have to use a custom reorder method since the normal :alpha for Autotest would put the 
  # files with ../ in the path before others.
  def reorder(files_to_test)
    ar_tests, sqlsvr_tests = files_to_test.partition { |k,v| k.starts_with?('../../../') }
    ar_tests.sort! { |a,b| a[0] <=> b[0] }
    sqlsvr_tests.sort! { |a,b| a[0] <=> b[0] }
    sqlsvr_tests + ar_tests
  end
  
end

