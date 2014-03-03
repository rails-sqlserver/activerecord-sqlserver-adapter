# encoding: UTF-8
require 'cases/sqlserver_helper'

class UnicodeTestSqlserver < ActiveRecord::TestCase


  context 'Testing basic saves and unicode limits' do

    should 'save and reload simple nchar string' do
      assert nchar_data = SqlServerUnicode.create!(nchar: 'A')
      assert_equal 'A', SqlServerUnicode.find(nchar_data.id).nchar
    end

    should 'save and reload simple nvarchar(max) string' do
      test_string = 'Ken Collins'
      assert nvarcharmax_data = SqlServerUnicode.create!(nvarchar_max: test_string)
      assert_equal test_string, SqlServerUnicode.find(nvarcharmax_data.id).nvarchar_max
    end

    should 'not work with ANSI_WARNINGS for string truncation' do
      SqlServerUnicode.create!(nchar_10: '01234567891')
    end

  end

  context 'Testing unicode data' do

    setup do
      @unicode_data = "\344\270\200\344\272\21434\344\272\224\345\205\255" # "一二34五六"
    end

    should 'insert and retrieve unicode data' do
      assert data = SqlServerUnicode.create!(nvarchar: @unicode_data)
      if connection_mode_dblib?
        assert_equal "一二34五六", data.reload.nvarchar
      elsif connection_mode_odbc?
        assert_equal "一二34五六", data.reload.nvarchar, 'perhaps you are not using the utf8 odbc that does this legwork'
      else
        raise 'need to add a case for this'
      end
      assert_equal Encoding.find('UTF-8'), data.nvarchar.encoding
    end

  end



end
