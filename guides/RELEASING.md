# Releasing

## Building locally

If you want to build the gem to test it locally run `bundle exec rake build`.

This command will build the gem in `pkg/activerecord-sqlserver-adapter-A.B.C.gem`, where `A.B.C` is the version in `VERSION` file.

## Releasing to RubyGems

Run `bundle exec rake release` to build the gem locally and push the `gem` file to RubyGems.
