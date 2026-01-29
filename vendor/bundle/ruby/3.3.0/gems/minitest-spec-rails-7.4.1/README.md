<a href="https://dhh.dk/2012/rails-is-omakase.html"><img src="https://user-images.githubusercontent.com/2381/34084174-246174da-e34a-11e7-9d36-94c9cde7b63d.png" width="233" height="154" /></a>

# Make Rails Use Minitest::Spec!
##### https://dhh.dk/2012/rails-is-omakase.html

The minitest-spec-rails gem makes it easy to use the Minitest::Spec DSL within your existing Rails 2.3, 3.x or 4.x test suite. It does this by forcing ActiveSupport::TestCase to utilize the Minitest::Spec::DSL.

[![Gem Version](https://badge.fury.io/rb/minitest-spec-rails.svg)](http://badge.fury.io/rb/minitest-spec-rails)
[![CI Status](https://github.com/metaskills/minitest-spec-rails/workflows/CI/badge.svg)](https://launch-editor.github.com/actions?nwo=metaskills%2Fminitest-spec-rails&workflowID=CI)
[![Maintainability](https://api.codeclimate.com/v1/badges/e67addda6fd009b68349/maintainability)](https://codeclimate.com/github/metaskills/minitest-spec-rails/maintainability)


## Usage

Existing or new Rails applications that use the default Rails testing structure can simply drop in the minitest-spec-gem and start writing their tests in the new spec DSL. Since Minitest::Spec is built on top of Minitest::Unit, a replacement for Test::Unit, all of your existing tests will continue to work.


#### Rails 4.1 to 6.0

Our master branch is tracking rails 5.1 up to 6.x active development.

```ruby
group :test do
  gem 'minitest-spec-rails'
end
```

#### For Rails 3.x or 4.0

Our [3-x-stable](https://github.com/metaskills/minitest-spec-rails/tree/3-x-stable) branch is meant for both Rails 3.x or 4.0 specifically. This version uses the latest 4.x series of minitest.

```ruby
group :test do
  gem 'minitest-spec-rails', '~> 4.7'
end
```


### How is this different than Minitest::Rails?

To start off both Mike Moore (@blowmage) and I have worked together and we both LOVE Minitest::Spec. Both projects aim to advocate Minitest and make Rails integration as easy as possible. However, there are a few key differences in our projects. Some of these differences may go away in time too. As always, choose the tool you think fits your needs. So how, is minitest-spec-rails different than [minitest-rails](https://github.com/blowmage/minitest-rails)?

  * We aim to leverage existing Rails test directories and files!
  * No special test helper and/or generators.
  * Easy migration path for existing Rails applications.
  * How we go about freedom patching Rails.
  * Fully support Ruby 1.8.7 with all legacy Test::Unit behavior.
  * Compatibility with ActiveSupport::TestCase's setup and teardowns.

So the goal of this project is to make Rails 3 or 4 applications just work as if rails-core had decided to support Minitest::Spec all along. We believe that eventually that day will come and when it does, all your tests will still work! So bundle up and get started!

```ruby
gem 'minitest-spec-rails'
```


## Test Styles

This <a href="https://chriskottom.com/freebies/cheatsheets_free.pdf">cheat sheet</a> shows both the Minitest::Unit assertions along with the Minitest::Spec assertion syntax. Remember, Minitest::Spec is built on top of Minitest::Unit which is a Test::Unit replacement. That means you can mix and match styles as you upgrade from Test::Unit to a more modern style. For example, both of these would work in Minitest::Spec and are interchangeable.

```ruby
# Minitest::Unit Assertion Style:
assert_equal 100, foo

# Minitest::Spec Assertion Style:
expect(foo).must_equal 100
```


```ruby
require 'test_helper'
class UserTest < ActiveSupport::TestCase
  let(:user_ken)   { User.create! :email => 'ken@metaskills.net' }
  it 'works' do
    expect(user_ken).must_be_instance_of User
  end
end
```

```ruby
require 'test_helper'
describe User do
  # THIS IS NOT RECOMMENDED!
end
```

RSpec 3 is also moving away from the outer describe test type inference, as described in this line from their [release notes](https://www.relishapp.com/rspec/rspec-rails/v/3-1/docs/changelog).

> Spec types are no longer inferred by location, they instead need to be explicitly tagged. The old behaviour is enabled by config.infer_spec_type_from_file_location!, which is still supplied in the default generated spec_helper.rb. (Xavier Shay, Myron Marston)

Not that we want to mimic RSpec, but the aim of this gem is very straight forward and minimalistic. We simply want to expose the Minitest Spec::DSL and core assertion style within ActiveSupport. Period. So it is very possible that us matching outer describe to classes is simply going to go away one day soon.

Just for reference, here is a full list of each of Rails test case we support.

```ruby
# Model Test (or anything else not listed below)
class UserTest < ActiveSupport::TestCase
end

# Controller Test
class UsersControllerTest < ActionController::TestCase
end

# Integration Tests - Must use subclass style!
class IntegrationTest < ActionDispatch::IntegrationTest
end

# Mailer Test
class UserMailerTest < ActionMailer::TestCase
end

# View Helper Test
class UsersHelperTest < ActionView::TestCase
end

# Job Helper Test
class MyJobTest < ActiveJob::TestCase
end
```


## Extras

We have baked in a few extra methods behind the scenes to minitest-spec-rails. Most directly support our needs to reflect on described classes, however, they may be useful to you too when meta-programming on top of minitest-spec-rails.

### #described_class
The `described_class` method is available both via a class method and an instance method in any Rails test case. It is guaranteed to work despite the described level too. This allows class level macros to be built, much like Shoulda. Remember, it can only do this if you follow Rails naming conventions for your tests.

```ruby
class UserTest < ActiveSupport::TestCase
  described_class # => User(id: integer, email: string)
  it 'works here' do
    described_class # => User(id: integer, email: string)
  end
  describe 'and' do
    it 'works here too' do
      described_class # => User(id: integer, email: string)
    end
  end
end
```

### Setup & Teardown Compatability

Rails ActiveSupport::TestCase allows multiple setup and teardown methods per class. It also allows you to specify these either with a symbol or a block. Unlike normal ActiveSupport setup and teardown callbacks, our blocks are evaluated in the scope of the instance, just like before and after. So this just works!

```ruby
class ActiveSupportCallbackTest < ActiveSupport::TestCase

  setup :foo
  setup :bar
  before { @bat = 'biz' }

  it 'works' do
    expect(@foo).must_equal 'foo'
    expect(@bar).must_equal 'bar'
    expect(@bat).must_equal 'biz'
  end

  private

  def foo ; @foo = 'foo' ; end
  def bar ; @bar = 'bar' ; end

end
```

### mini_shoulda

If you are migrating away from Shoulda, then minitest-spec-rails' mini_shoulda feature will help. To enable it, set the following configuration in your test environment file.

```ruby
# In config/environments/test.rb
config.minitest_spec_rails.mini_shoulda = true
```

Doing so only enables a few aliases that allow the Shoulda `context`, `should`, and `should_eventually` methods. The following code demonstrates the full features of the mini_shoulda implementation. It basically replaces the shell of [shoulda-context](https://github.com/thoughtbot/shoulda-context) in a few lines of code.

```ruby
class PostTests < ActiveSupport::TestCase
  setup    { @post = Post.create! :title => 'Test Title', :body => 'Test body' }
  teardown { Post.delete_all }
  should 'work' do
    @post.must_be_instance_of Post
  end
  context 'with a user' do
    should_eventually 'have a user' do
      # ...
    end
  end
end
```

If you prefer the assertions provided by shoulda-context like `assert_same_elements`, then you may want to consider copying them [from here](https://github.com/thoughtbot/shoulda-context/blob/master/lib/shoulda/context/assertions.rb) and including them in `Minitest::Spec` yourself. I personally recommend just replacing these assertions with something more modern. A few examples are below.

```ruby
assert_same_elements a, b         # From
expect(a.sort).must_equal b.sort  # To

assert_does_not_contain a, b  # From
expect(a).wont_include b      # To
```

### Matchers

**I highly suggest that you stay away from matchers** since Minitest::Spec gives you all the tools you need to write good tests. Staying away from matchers will make your code's tests live longer. So my advice is to stay away from things like `.should ==` and just write `.must_equal` instead. However, if matchers are really your thing, I recommend the [minitest-matchers](https://github.com/wojtekmach/minitest-matchers) gem. You can also check out the [valid_attribute](https://github.com/bcardarella/valid_attribute) gem built on top of minitest-matchers.

```ruby
describe Post do
  subject { Post.new }
  it { must have_valid(:title).when("Hello") }
  it { wont have_valid(:title).when("", nil, "Bad") }
end
```

Alternatively, try the [mintest-matchers_vaccine](https://github.com/rmm5t/minitest-matchers_vaccine) gem to avoid _infecting_ the objects that you want to test.

```ruby
describe User do
  subject { User.new }
  it "should validate email" do
    must have_valid(:email).when("a@a.com", "foo@bar.com")
    wont have_valid(:email).when(nil, "", "foo", "foo@bar")
  end
end
```

## Gotchas

### Assertion Methods

If you are upgrading from Test::Unit, there are a few missing assertions that have been renamed or are no longer available within Minitest.

* The method `assert_raise` is renamed `assert_raises`.
* There is no method `assert_nothing_raised`. There are good reasons for this on [Ryan's blog entry](http://blog.zenspider.com/blog/2012/01/assert_nothing_tested.html).

### Mocha

If you are using [Mocha](https://github.com/freerange/mocha) for mocking and stubbing, please update to the latest, 0.13.1 or higher so it is compatible with the latest Minitest. If you do not like the deprecation warnings in older versions of Rails, just add this below the `require 'rails/all'` within your `application.rb` file :)

```ruby
require 'mocha/deprecation'
Mocha::Deprecation.mode = :disabled
```

### Rails 3.0.x

If you are using minitest-spec-rails with Rails 3.0, then your controller and mailer tests will need to use the `tests` interface for the assertions to be setup correctly within sub `describe` blocks. I think this is a bug with `class_attribute` within Rails 3.0 only. So use the following patterns.

```ruby
class UsersControllerTest < ActionController::TestCase
  tests UsersController
end
class UserMailerTest < ActionMailer::TestCase
  tests UserMailer
end
```

### Rails 3.1 & 3.2

If your view helper tests give you an eror like this: `RuntimeError: In order to use #url_for, you must include routing helpers explicitly.`, this is something that is broken only for Rails 3.1 and 3.2, both 3.0 and 4.0 and above do not exhibit this error. I have heard that if you `include Rails.application.routes.url_helpers` in your tests or inject them into the helper module before the test it may work. Lemme know what you find out.


## Contributing

We run our tests on GitHub Actions. If you detect a problem, open up a github issue or fork the repo and help out. After you fork or clone the repository, the following commands will get you up and running on the test suite.

```shell
$ bundle install
$ bundle exec appraisal update
$ bundle exec appraisal rake test
```

We use the [appraisal](https://github.com/thoughtbot/appraisal) gem from Thoughtbot to help us generate the individual gemfiles for each Rails version and to run the tests locally against each generated Gemfile. The `rake appraisal test` command actually runs our test suite against all Rails versions in our `Appraisal` file. If you want to run the tests for a specific Rails version, use `bundle exec appraisal -h` for a list. For example, the following command will run the tests for Rails 4.1 only.

```shell
$ bundle exec appraisal rails_v6.0.x rake test
$ bundle exec appraisal rails_v6.1.x rake test
$ bundle exec appraisal rails_v7.0.x rake test
```

We have a few branches for each major Rails version.

* [2-3-stable](https://github.com/metaskills/minitest-spec-rails/tree/2-3-stable) - Tracks Rails 2.3.x with MiniTest 4.x.
* [3-x-stable](https://github.com/metaskills/minitest-spec-rails/tree/3-x-stable) - Oddly tracks Rails 3.x and 4.0 with MiniTest 4.x.
* master - Currently tracks Rails 4.1 which uses Minitest 5.0.
