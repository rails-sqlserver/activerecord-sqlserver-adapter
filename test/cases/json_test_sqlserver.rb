require 'cases/helper_sqlserver'

if ActiveRecord::Base.connection.supports_json?
class JsonTestSQLServer < ActiveRecord::TestCase

  before do
    @o1 = SSTestDatatypeMigrationJson.create! json_col: { 'a' => 'a', 'b' => 'b', 'c' => 'c' }
    @o2 = SSTestDatatypeMigrationJson.create! json_col: { 'a' => nil, 'b' => 'b', 'c' => 'c' }
    @o3 = SSTestDatatypeMigrationJson.create! json_col: { 'x' => 1, 'y' => 2, 'z' => 3 }
    @o4 = SSTestDatatypeMigrationJson.create! json_col: { 'array' => [1, 2, 3] }
    @o5 = SSTestDatatypeMigrationJson.create! json_col: nil
  end

  it 'can return and save JSON data' do
    _(SSTestDatatypeMigrationJson.find(@o1.id).json_col).must_equal({ 'a' => 'a', 'b' => 'b', 'c' => 'c' })
    @o1.json_col = { 'a' => 'a' }
    _(@o1.json_col).must_equal({ 'a' => 'a' })
    @o1.save!
    _(@o1.reload.json_col).must_equal({ 'a' => 'a' })
  end

  it 'can use ISJSON function' do
    _(SSTestDatatypeMigrationJson.where('ISJSON(json_col) > 0').count).must_equal 4
    _(SSTestDatatypeMigrationJson.where('ISJSON(json_col) IS NULL').count).must_equal 1
  end

  it 'can use JSON_VALUE function' do
    _(SSTestDatatypeMigrationJson.where("JSON_VALUE(json_col, '$.b') = 'b'").count).must_equal 2
  end

end
end
