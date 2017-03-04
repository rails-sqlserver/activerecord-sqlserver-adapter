require 'cases/helper_sqlserver'
require 'models/book'

class ScratchpadTestSQLServer < ActiveRecord::TestCase

  it 'helps debug things' do
    $FOO = true
    1000.times { Book.create! name: 'test' }
  end

end
