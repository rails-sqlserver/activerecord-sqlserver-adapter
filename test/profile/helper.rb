require 'cases/sqlserver_helper'
require 'ruby-prof'
require 'memprof'

class ActiveRecord::TestCase
  
  
  protected
  
  def mem_profile(*args)
    Memprof.track do
      yield
    end
  end
  
  def ruby_profile(name)
    result = RubyProf.profile { yield }
    [:flat,:graph,:html].each do |printer|
      save_ruby_prof_report(result, name, printer)
    end
  end
  
  def save_ruby_prof_report(result, name, printer)
    ptr = case printer
          when :flat  then RubyProf::FlatPrinter
          when :graph then RubyProf::GraphPrinter
          when :html  then RubyProf::GraphHtmlPrinter
          end
    file_name = printer == :html ? "#{name}_graph.html" : "#{name}_#{printer}.txt"
    file_path = File.join(SQLSERVER_TEST_ROOT, 'profile', 'output', file_name)
    File.open(file_path,'w') do |file|
      printer == :html ? ptr.new(result).print(file) : ptr.new(result).print(file,0)
    end
  end
  
end

