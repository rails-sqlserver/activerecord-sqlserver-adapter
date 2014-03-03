require 'benchmark'
require 'cases/sqlserver_helper'
require 'models/topic'
require 'models/reply'

class GcProfileCase < ActiveRecord::TestCase

  fixtures :topics

  setup do
    create_mass_topics unless @created_mass_topics
    @connection = ActiveRecord::Base.connection
    @select_statement = "SELECT [topics].* FROM [topics]"
  end

  def test_coercion
    bench_allocations('coercion') do
      Topic.all(limit: 100).each do |t|
        t.attributes.keys.each do |k|
          t.send(k.to_sym)
        end
      end
    end
  end

  def test_select
    bench_allocations('select') do
      @connection.send :select, @select_statement
    end
  end

  def test_select_one
    bench_allocations('select_one') do
      100.times { @connection.select_one(@select_statement) }
    end
  end

  def test_columns
    bench_allocations('columns') do
      100.times do
        Topic.reset_column_information
        Topic.columns
      end
    end
  end


  protected

  def create_mass_topics
    GC::Profiler.clear
    GC::Profiler.disable
    all_topics = Topic.all
    100.times { all_topics.each { |t| Topic.create! t.attributes } }
    @created_mass_topics = true
    GC.start
    GC::Profiler.enable
    GC::Profiler.clear
  end

  def bench_allocations(feature, iterations=10, &blk)
    puts "\nGC overhead for #{feature}"
    GC::Profiler.clear
    GC::Profiler.enable
    iterations.times{ blk.call }
    GC::Profiler.report(STDOUT)
    GC::Profiler.disable
  end

end





