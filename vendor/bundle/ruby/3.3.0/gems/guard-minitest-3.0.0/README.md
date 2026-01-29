# Guard::Minitest

[![Gem Version](http://img.shields.io/gem/v/guard-minitest.svg)](https://rubygems.org/gems/guard-minitest)
[![Build Status](https://github.com/guard/guard-minitest/workflows/CI/badge.svg)](https://github.com/guard/guard-minitest/actions/workflows/ci.yml)
[![Gem Downloads](https://img.shields.io/gem/dt/guard-minitest.svg)](https://rubygems.org/gems/guard-minitest)

Guard::Minitest allows to automatically & intelligently launch tests with the
[minitest framework](https://github.com/seattlerb/minitest) when files are modified.

* Compatible with minitest >= 5.0
* Tested against Ruby >= 3.2.0

*IMPORTANT NOTE: `guard-minitest` does not depend on `guard` due to obscure issues - you must either install `guard` first or add it explicitly in your `Gemfile` (see: [#131](https://github.com/guard/guard-minitest/pull/131) for details)*

## Install

Please be sure to have [Guard](http://github.com/guard/guard) installed before you continue.

The simplest way to install Guard::Minitest is to use [Bundler](http://gembundler.com/).

Add Guard::Minitest to your `Gemfile`:

```ruby
group :development do
  gem 'guard' # NOTE: this is necessary in newer versions
  gem 'guard-minitest'
end
```

and install it by running Bundler:

```bash
$ bundle
```

Add guard definition to your Guardfile by running the following command:

```bash
guard init minitest
```

## Ruby on Rails

### Spring

Due to complexities in how arguments are handled and running tests for selected files, it's best to use the following spring command:

```ruby
guard "minitest", spring: "bin/rails test" do
  # ...
end
```

(For details see issue [#130](https://github.com/guard/guard-minitest/issues/130)).

### Rails gem dependencies

Ruby on Rails lazy loads gems as needed in its test suite.
As a result Guard::Minitest may not be able to run all tests until the gem dependencies are resolved.

To solve the issue either add the missing dependencies or remove the tests.

Example:

```
Specify ruby-prof as application's dependency in Gemfile to run benchmarks.
```

Rails automatically generates a performance test stub in the `test/performance` directory which can trigger this error.
Either add `ruby-prof` to your `Gemfile` (inside the `test` group):

```ruby
group :test do
   gem 'ruby-prof'
end
```

Or remove the test (or even the `test/performance` directory if it isn't necessary).

## Usage

Please read [Guard usage doc](http://github.com/guard/guard#readme)

## Guardfile

Guard::Minitest can be adapated to all kind of projects.
Please read [guard doc](http://github.com/guard/guard#readme) for more info about the Guardfile DSL.

### Standard Guardfile when using Minitest::Unit

```ruby
guard :minitest do
  watch(%r{^test/(.*)\/?test_(.*)\.rb$})
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r{^test/test_helper\.rb$})      { 'test' }
end
```

### Standard Guardfile when using Minitest::Spec

```ruby
guard :minitest do
  watch(%r{^spec/(.*)_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})         { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/spec_helper\.rb$}) { 'spec' }
end
```

## Options

### List of available options

```ruby
all_on_start: false               # run all tests in group on startup, default: true
all_after_pass: true              # run all tests in group after changed specs pass, default: false
cli: '--test'                     # pass arbitrary Minitest CLI arguments, default: ''
test_folders: ['tests']           # specify an array of paths that contain test files, default: %w[test spec]
include: ['lib']                  # specify an array of include paths to the command that runs the tests
test_file_patterns: %w[test_*.rb] # specify an array of patterns that test files must match in order to be run, default: %w[*_test.rb test_*.rb *_spec.rb]
spring: true                      # enable spring support, default: false
zeus: true                        # enable zeus support; default: false
drb: true                         # enable DRb support, default: false
bundler: false                    # don't use "bundle exec" to run the minitest command, default: true
rubygems: true                    # require rubygems when running the minitest command (only if bundler is disabled), default: false
env: {}                           # specify some environment variables to be set when the test command is invoked, default: {}
all_env: {}                       # specify additional environment variables to be set when all tests are being run, default: false
autorun: false                    # require 'minitest/autorun' automatically, default: true
```

### Options usage examples

#### `:test_folders` and `:test_file_patterns`

You can change the default location of test files using the `:test_folders` option and change the pattern of test files using the `:test_file_patterns` option:

```ruby
guard :minitest, test_folders: 'test/unit', test_file_patterns: '*_test.rb' do
  # ...
end
```

#### `:cli`

You can pass any of the standard MiniTest CLI options using the `:cli` option:

```ruby
guard :minitest, cli: '--seed 123456 --verbose' do
  # ...
end
```

#### `:spring`

[Spring](https://github.com/jonleighton/spring) is supported (Ruby 1.9.X / Rails 3.2+ only), but you must enable it:

```ruby
guard :minitest, spring: true do
  # ...
end
```

Since version 2.3.0, the default Spring command works is `bin/rake test` making the integration with your Rails >= 4.1 app effortless.

If you're using an older version of Rails (or no Rails at all), you might want to customize the Spring command, e.g.:

```ruby
guard :minitest, spring: 'spring rake test' do
  # ...
end
```

#### `:zeus`

[Zeus](https://github.com/burke/zeus) is supported, but you must enable it.
Please note that notifications support is very basic when using Zeus. The zeus client exit status is evaluated, and
a Guard `:success` or `:failed` notification is triggered. It does not include the test results though.

If you're interested in improving it, please
[open a new issue](https://github.com/guard/guard-minitest/issues/new).

If your test helper matches the test_file_patterns, it can lead to problems
as guard-minitest will submit the test helper itself to the zeus test
command when running all tests. For example, if the test helper is
called ``test/test_helper.rb`` it will match ``test_*.rb``. In this case you can
either change the test_file_patterns or rename the test helper.

```ruby
guard :minitest, zeus: true do
  # ...
end
```

#### `:drb`

[Spork / spork-testunit](https://github.com/sporkrb/spork-testunit) is supported, but you must enable it:

```ruby
guard :minitest, drb: true do
  # ...
end
```
The drb test runner honors the :include option, but does not (unlike the
default runner) automatically include :test_folders.  If you want to
include the test paths, you must explicitly add them to :include.

## Development

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/guard-minitest/master/frames).
* Source hosted at [GitHub](https://github.com/guard/guard-minitest).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested. All specs run by Travis CI must pass.
* Update the [README](https://github.com/guard/guard-minitest/blob/master/README.md).
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

## Maintainer

[Eric Steele](https://github.com/genericsteele)

## Author

[Yann Lugrin](https://github.com/yannlugrin)

## Contributors

[https://github.com/guard/guard-minitest/graphs/contributors](https://github.com/guard/guard-minitest/graphs/contributors)
