## 7.4.0, 7.4.1

- Fix require `action_cable/channel/test_case` errors with Rails 5.x. Fixes #124

## 7.3.0

- Fix require `action_cable/channel/test_case` errors with Rails 5.x. Fixes #124

## 7.2.0

- Wrap action_view init in config.to_prepare block. Fixes #122. Thanks @Hal-Sumi

## 7.1.0

- Use Minitest instead of MiniTest. Fixes #119. Thanks @evgeni
- Fix ActionCable::Channel::TestCase support. Fixes #118. Thanks @marcoroth
- Add support for ActionCable::Channel::TestCase. Fixes #117. Thanks @tijn

## 7.0.0

- Add support for ActionCable::Channel::TestCase. Fixed #117. Thanks @tijn
- Remove automated tests for Rails v5 and Ruby v2.
- Update all of our tests and examples to use non-global expectations.
- Remove `Rails.application.reloader.to_prepare` for `ActionViewBehavior`.

## 6.2.0

- Remove 'ENV['RAILS_ENV']=='test' from railtie.rb Fixes #114. Thanks @Qqwy

## 6.1.0

- Fix Rails v7 autoloading with ViewComponent. Thanks @woller

## 6.0.4

- Fixed parallel tests with relative paths. Thanks @jlsherrill

## 6.0.3

- Better ActionView load. Fixed #105. Thanks @zofrex

## 6.0.2

- Fixed parallel tests in Rails v6.

## 6.0.1

- Changed gemspec to `railties` vs `rails`. Thanks @seuros

## 6.0.0

- Bumping to be major with latest testing versions.

## 5.6.0

- Add Rails v6 via gem spec support.

## 5.5.0

- Fix source_location of methods defined with `test`. Fixes #91. Thanks @barrettkingram

## 5.4.0

- Use ENV['RAILS_ENV'] for initializer guards vs memo'ed Rails.env. Fixes #72.

## 5.3.0

- Allow Rails 4.1 to new 5.x to be supported.

## 5.2.2

- Fix ActiveJob support for `described_class`. Thanks @pschambacher.

## 5.2.1

- Only add our Thread.current[:current_spec] hack if needed. Fixes #45.

## 5.2.0

- Added ActiveJob support. Fixes #59. Thanks @xpepermint.

## 5.1.1

- Fix an issue where `describe` method was removed. Fixes #55 & #50
  [41a0f851](https://github.com/metaskills/minitest-spec-rails/commit/41a0f851c8a290f59feb1cb8b20759f0e2a9697a)

## 5.1.0

No release notes yet. PRs welcome!

## 5.0.4

- Fixed ActiveSupport's Declarative#test forwarded implementation. Fixed #46.

## 5.0.3

- Fixed ActionView load order & url helpers. Fixes #42.

## 5.0.2

- Fixed initialization callbacks for latest Rails 4.1. Fixes #39.

## 5.0.1

- Change initialization so that ActiveSupport always comes first.

## 5.0.0

- Minitest 5.x and Rails 4.1 compatability. Fixes #36.
- Fix nested described test names along with Minitest::Spec.describe_stack. Fixed #21.
- Leverage `ActiveSupport::Testing::ConstantLookup` for our `described_class` interface.

## 4.7.6

- Fix nested described test names. Fixes #21.

## 4.7.5

- Fixed gemspec using '>= 3.0', '< 4.1'. Fixed #35.

## 4.7.4

- Enforces case sensitivity on registered spec types. Fixes #26.

## 4.7.3

- Allow using ActiveSupport's Declarative#test as an alias to it. Thanks @ysbaddaden. Fixes #23.

## 4.7.2

- Register non ActiveRecord::Base classes correctly. Thanks @mptre.

## 4.7.1

- Only use a TU shim for Ruby 1.8. See README for info. Fixes #18.

## 4.7.0

- Use Minitest::Spec::DSL provided by Minitest 4.7.

## 4.3.8

- Less coupling to ActiveRecord ORM, works for MongoDB now. Thanks @kimsuelim

## v4.3.7

- Fix helper test bug where calling methods in first context block blew up. Fixes #13.

## v4.3.6

- Only require the freedom patches and autorun when Rails.env.test?

## v4.3.5

- Make sure #described_class works in ActiveSupport::TestCase class level.

## v4.3.4

- Add mini_should support and talk about matchers.

## v4.3.3

- Fix MiniTest::Unit::TestCase hack for Rails 4, ignore in Rails 3.

## v4.3.2

- Way better support for controller_class, mailer_class, and helper_class reflection.

## v4.3.1

- Eager load controller_class, mailer_class, and helper_class.

## v4.3.0

- All new MiniTest::Spec for Rails!!! Tested to the hilt!!!
- Track MiniTest's major/minior version number.

## v3.0.7

- Must use MiniTest version ~> 2.1. As 3.x will not work.

## v3.0.6

- Use #constantize vs. #safe_constantize for Rails 3.0 compatability.

## v3.0.5

- Use ActionController::IntegrationTest vs. ActionDispatch::IntegrationTest

## v3.0.4

- Use class app setter for integration tests.

## v3.0.3

- Stronger test case organization where we properly setup functional and integraiton tests
  while also allowing an alternate pure MiniTest::Spec outter file describe block. [Jack Chu]

## v3.0.2

- Remove version deps on minitest since v3 is out. Should work with any v2/3 version.

## v3.0.1

- Add rails to the gemspec.

## v3.0.0

- Initial Release, targeted to Rails 3.x.
