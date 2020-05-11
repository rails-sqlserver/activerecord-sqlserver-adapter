# frozen_string_literal: true

require "cases/helper"
require "support/connection_helper"
require "models/admin"
require "models/admin/account"
require "models/admin/randomly_named_c1"
require "models/admin/user"
require "models/binary"
require "models/book"
require "models/bulb"
require "models/category"
require "models/post"
require "models/comment"
require "models/company"
require "models/computer"
require "models/course"
require "models/developer"
require "models/dog"
require "models/doubloon"
require "models/joke"
require "models/matey"
require "models/other_dog"
require "models/parrot"
require "models/pirate"
require "models/randomly_named_c1"
require "models/reply"
require "models/ship"
require "models/task"
require "models/topic"
require "models/traffic_light"
require "models/treasure"
require "tempfile"

class FixturesAidoTest < ActiveRecord::TestCase
  include ConnectionHelper

  self.use_instantiated_fixtures = true
  self.use_transactional_tests = false

  # other_topics fixture should not be included here
  fixtures :topics, :developers, :accounts, :tasks, :categories, :funny_jokes, :binaries, :traffic_lights

  FIXTURES = %w( accounts binaries companies customers
                 developers developers_projects entrants
                 movies projects subscribers topics tasks )
  MATCH_ATTRIBUTE_NAME = /[a-zA-Z][-\w]*/

  def setup
    Arel::Table.engine = nil # should not rely on the global Arel::Table.engine
  end

  def teardown
    Arel::Table.engine = ActiveRecord::Base
  end

  def test_binary_in_fixtures
    data = File.open(ASSETS_ROOT + "/flowers.jpg", "rb") { |f| f.read }
    data.force_encoding("ASCII-8BIT")
    data.freeze


    # binding.irb

    puts "*" * 20
    puts "test_binary_in_fixtures"
    puts "*" * 20

    puts "data.length=#{data.length}"
    puts "@flowers.data.length=#{@flowers.data.length}"
    puts "@binary_helper.data.length=#{@binary_helper.data.length}"


    assert_equal data, @flowers.data
    assert_equal data, @binary_helper.data
  end



end
