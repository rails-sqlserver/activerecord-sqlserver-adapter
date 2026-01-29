## (unreleased)

## 3.4.0

* Add Ruby 4.0 to the cross compile list
* No longer ship a precompiled Gem for Ruby 2.7
  * This is due to an [upstream change](https://github.com/rake-compiler/rake-compiler-dock/releases/tag/v1.11.0). Users on Windows and Linux on Ruby v2.7 are advised to either upgrade or install FreeTDS manually.
* Use freetds v1.5.10 and OpenSSL v3.6.0 for Windows and Linux builds.
* Lower `bigdecimal` requirement to `>= 2.0.0` (was 3.0 only) to allow `bigdecimal` 4.0 on Ruby 4.0. Closes #601.

## 3.3.0

* Use freetds v1.5.4 and OpenSSL v3.5.2 for Windows and Linux builds.
* Use `TypedData` in C-Land.

## 3.2.1

* Ensure the native Gem loads on Windows. Fixes #581.
* Use OpenSSL v3.4.1 for Windows and Linux builds.

## 3.2.0

* Reduce number of files shipped with precompiled Windows gem
* Provide precompiled gem for Linux (GNU + MUSL / 64-bit x86 + ARM)
* Fix wrappers for `tsql` and `defncopy` utility.
* Use libiconv v1.18 and freetds v1.4.26 for Windows and Linux builds

## 3.1.0

* Add Ruby 3.4 to the cross compile list

## 3.0.0

* Drop support for Ruby < 2.7
* Drop support for SQL Server < 2017
* Drop support for FreeTDS < 1.0
* No longer provide a 32-bit Windows build
* Raise error if FreeTDS is unable to send command buffer to the server
* Use freetds v1.4.23, libiconv v1.17 and OpenSSL v3.4.0 for Windows builds
* Add `bigdecimal` to dependencies

## 2.1.7

* Add Ruby 3.3 to the cross compile list

## 2.1.6

* Add Ruby 3.0, 3.1, and 3.2 to the cross compile list
* Fix segfault when asking if client was dead after closing it. Fixes #519.
* Mark `alloc` function as undefined on `TinyTds::Result`. Fixes #515.
* Fix Gem installation on Windows by adding default freetds msys path. Fixes #522
* Search for `freetds` in `/opt/homebrew` when installing on Apple Silicon. Fixes #484, #492 and #508.

## 2.1.5

* Fix compilation errors for Amazon Linux 1. Fixes #495.
* Fix segfault for login timeouts

## 2.1.4

* Improve handling of network related timeouts
* Fix error reporting when preceded by info message

## 2.1.3

* Removed old/unused appveyor config
* Remove old Rubies from CI & cross compile list
* Add Ruby 2.6 and 2.7 to the cross compile list

## 2.1.2

* Use Kernel.BigDecimal vs BigDecimal.new. Fixes #409.
* Change `DBSETUTF16` abscence warning message. Fixes #410.
* Add Windows binary for Ruby-2.5. Fixes #408.

## 2.1.1

* Move message_handler from a shared value to userdata.


## 2.1.0

* Support RubyInstaller2 for Windows. Fixes #365.
* Support the FREETDS_DIR environment variable. Fixes #371.
* Rename binstubs to tsql-ttds and defncopy-ttds
* Support separate timeout values per connection Fixes #348.
* Allow client proc to capture INFO messages. Fixes #352.
* Use official HTTP mirrors instead of FTP. Fixes #384.


## 2.0.0

* Stop building FreeTDS as a part of the extension build.


## 1.3.0

* FreeTDS: Link libgcc statically for Windows. (#351) Fixes #349.


## 1.2.0

* Use OpenSSL v1.1.0e & FreeTDS v1.00.27 for Windows builds.


## 1.1.0

* Use rake-compiler-dock v0.6.0
* Handle SYBVARIANT types from SQL function. Fixes #317. Fixed #321.
* Fix `use_utf16` optoin for booleans. Fixes #314
* Add `-q` check for bin puts. Fixes #318
* Use FreeTDS 1.00.21.
* Appveyor tests only 2012, 2014 with one Ruby, 23-x64.
* CircleCI & TravisCI both test 2016.


## 1.0.5

* Windows Static Builds - Use FreeTDS 1.00.15, OpenSSL 1.0.2j.
* Appveyor tests 2012, 2014, 2016.
* Error messages greater than 1024 chars generates a buffer overflow. Fixes #293.
* Ensures numeric options are treated numerically Fixes #303.
* New `:contained` login option. May deprecate `:azure`. Fixes #292.
* New `:use_utf16` login option. Toggle UCS-2 or UTF-16. Default true.


## 1.0.4

* Use FreeTDS 1.0 final


## 1.0.3

* Use FreeTDS 1.0rc5 for cross compile windows gems.
* Ensure we only work with latest FreeTDS v0.95.x or higher.


## 1.0.2

* Cross compile w/2.3.0 using rake-compiler-dock ~> 0.5.1. Fixes #268 #270.
* Use FreeTDS 1.0rc4 for cross compile windows gems.


## 1.0.1

* Fix ruby exe's in non-platform gem.


## 1.0.0

* Tested with FreeTDS 1.0.
* Add emoji support by default using FreeTDS v1.0 in docs.


* 0.9.5 * (release candidates only)

* Binstub wrappers for `tsql`. Fixes #227 #251
* Add support for 2008 data types. Must use TDSVER 7.3 or higher. Fixes #244 #251
  - [date]
  - [datetime2]
  - [datetimeoffset]
  - [time]
* Default FreeTDS to 0.95. Support 0.91 Alternate Fixes #233
  - Allow our `tds_version` to mirror TDSVER env var. Ex '7.3' vs '73'.
  - Change error handler for `SYBEICONVO` to hard return INT_CANCEL.
* Made sure Azure logins are user@short vs. long domain. Fixes #229
* Removed Ruby 1.9.3 from CI builds.
* CI now tests Azure too.
* Fixed compiler warnings on all platforms. Fixed #241
* FreeTDS - Remove support for bad iconv.


## 0.7.0

* Refactor build of FreeTDS & Iconv recipes. Add OpenSSL. Merged #207.
* Ensure zero terminated strings, where C-str pointers are expected. Use StringValueCStr() Fixes #208.
* Revert 999fa571 so timeouts do not kill the client. Fixes #179.
* Remove `sspi_w_kerberos.diff` patch. Not needed anymore.
* Tested again on Azure. Added notes to README on recommended settings.
* Replace `rb_thread_blocking_region` (removed in Ruby 2.2.0) w/`rb_thread_call_without_gvl`. Fixes #182.
* Remove 30 char password warning. Fixes #172.
* Remove Ruby 1.8.6 support. We always use Time vs edge case DateTime.


## 0.6.2

* Support an optional environment variable to find FreeTDS. Fixes #128.
* Allow Support for 31+ Character Usernames/Passwords. Fixes #134. Thanks @wbond.
* Stronger Global VM Lock support for nonblocking connections. Fixes #133. Thanks @wbond.
* Timeout fix for working with Azure SQL. Fixes #138.
* Correctly handle requests that return multiple results sets via `.do`, such
  as backups and restores. Fixes #150.


## 0.6.1

Use both dbsetversion() vs. dbsetlversion. Partially reverts #62.


## 0.6.0

* Use dbsetversion() vs. dbsetlversion. Fixes #62.
* Remove Ruby 1.8 support.
* Implement misc rb_thread_blocking_region support. Fixes #121. Thanks @lepfhty.
* Test FreeTDS v0.91.89 patch release.
* Fix lost connection handling. Fixes #124. Thanks @krzcho.
* Remove unused variable. Fixes #103. Thanks @jeremyevans.
* Remove need to specify username for Windows Authentication.
* Use proper SQL for returning IDENTITY with Sybase. Fixes #95.
* Compile windows with `--enable-sspi`.
* Allow MiniPortile to build any FreeTDS version we need. Fixes #76.
* Always convert password option to string. Fixes #92.
* Move test system to real MiniTest::Spec. All tests pass on Azure too.
* Raise and handle encoding errors on DB writes. Fixes #89.


## 0.5.1

* Change how we configure with iconv, basically it is always needed. Fixes #11 & #69.


## 0.5.0

* Copy mysql2s handling of Time and Datetime so 64bit systems are leveraged. Fixes #46 and #47. Thanks @lsylvester!
* Add CFLAGS='-fPIC' for libtool. Fix TDS version configs in our ports file. Document. Fixes #45
* Update our TDS version constants to reflect changed 8.0/9.0 to 7.1/7.2 DBLIB versions in FreeTDS
  while making it backward compatible, again like FreeTDS. Even tho you can not configure FreeTDS with
  TDS version 7.2 or technically even use it, I added tests to prove that we correctly handle both
  varchar(max) and nvarchar(max) with large amounts of data.
* FreeTDS 0.91 has been released. Update our port scripts.
* Add test for 0.91 and higher to handle incorrect syntax in sp_executesql.
* Returning empty result sets with a command batch that has multiple statements is now the default. Use :empty_sets => false to override.
* Do not raise a TinyTds::Error with our message handler unless the severity is greater than 10.


## 0.4.5

* Includes precompiled Windows binaries for FreeTDS 0.91rc2 & LibIconv. No precompiled OpenSSL yet for Windows to SQL Azure.
* Fixed symbolized unicode column names.
* Use same bigint ruby functions to return identity. Hopefully fixes #19.
* Release static libs for Windows.
* Change how :host/:port are implemented. Now sending "host:port" to :dataserver.


## 0.4.4

* New :host/:port connection options. Removes need for freetds.conf file.


## 0.4.3

* New Client#active? method to check for good connection. Always use this abstract method.
* Better SYBEWRIT "Write to SQL Server failed." error handling. New Client#dead? check.
* Azure tested using latest FreeTDS with submitted patch. https://gist.github.com/889190


## 0.4.2

* Iconv is a dep only when compiling locally. However, left in the ability to configure
  it for native gem installation but you must use
  --enable-iconv before using --with-iconv-dir=/some/dir
* Really fix what 0.4.1 was supposed to do, force SYBDBLIB compile.


## 0.4.1

* Undefine MSDBLIB in case others have explicitly compiled FreeTDS with "MS db-lib source compatibility: yes".


## 0.4.0

* Allow SYBEICONVI errors to pass thru so that bad data is converted to ? marks.
* Build native deps using MiniPortile [Luis Lavena]
* Allow Result#fields to be called before iterating over the results.
* Two new client helper methods, #sqlsent? and #canceled?. Possible to use these to determine current
  state of the client and the need to use Result#cancel to stop processing active results. It is also
  safe to call Result#cancel over and over again.
* Look for the syb headers only.
* Fix minitest global matchers warnings.
* Fix test warnings.


## 0.3.2

* Small changes while testing JRuby. Using options hash for connect vs many args.


## 0.3.1

* Fix bad gem build.


## 0.3.0

* Access stored procedure return codes.
* Make sure dead or not enabled connections are handled.
* Fix bad client after timeout & read from server errors.


## 0.2.3

*  Do not use development ruby/version, but simple memoize an eval check on init to find out, for 1.8.6 reflection.


## 0.2.2

* Fixed failing test in Ruby 1.8.6. DateTime doesn't support fractional seconds greater than 59.
  See: http://redmine.ruby-lang.org/issues/show/1490 [Erik Bryn]


## 0.2.1

* Compatibility with 32-bit systems. Better cross language testing. [Klaus Gundermann]


## 0.2.0

* Convert GUID's in a more compatible way. [Klaus Gundermann]
* Handle multiple result sets in command buffer or stored procs. [Ken Collins]
* Fixed some compiler warnings. [Erik Bryn]
* Avoid segfault related to smalldatetime conversion. [Erik Bryn]
* Properly encode column names in 1.9. [Erik Bryn]


## 0.1.0 Initial release!
