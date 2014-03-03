AREL_TEST_ROOT = File.expand_path(File.join(Gem.loaded_specs['arel'].full_gem_path,'test'))
$LOAD_PATH.unshift AREL_TEST_ROOT

# TODO: Find A  better way to run Arel tests without failing on
# SQL Server brackets instead of quotes
 class Object
  def must_be_like other
    actual   =       gsub(/\s+/, ' ').gsub(/\[|\]/,'"').gsub(/N\'/,'\'').strip
    expected = other.gsub(/\s+/, ' ').strip
    actual.must_equal expected
  end
 end


# Useful for debugging Arel.
# You can call it like  arel_to_png(User.where(name: "foo").arel)
def arel_to_png(arel, file_name = "query")
  graph = GraphViz.parse_string(arel.to_dot)
  graph.output(png: "#{file_name}.png")
end