require "date"
require "bigdecimal"

require "tiny_tds/version"
require "tiny_tds/error"
require "tiny_tds/client"
require "tiny_tds/result"
require "tiny_tds/gem"

module TinyTds
  # Is this file part of a fat binary gem with bundled freetds?
  # This path must be enabled by add_dll_directory on Windows.
  FREETDS_LIB_PATH = TinyTds::Gem.ports_bin_and_lib_paths.first

  add_dll_path = proc do |path, &block|
    if RUBY_PLATFORM =~ /(mswin|mingw)/i && path
      begin
        require "ruby_installer/runtime"
        RubyInstaller::Runtime.add_dll_directory(path, &block)
      rescue LoadError
        old_path = ENV["PATH"]
        ENV["PATH"] = "#{path};#{old_path}"
        block.call
        ENV["PATH"] = old_path
      end
    else
      # libsybdb is found by a relative rpath in the cross compiled extension dll
      # or by the system library loader
      block.call
    end
  end

  add_dll_path.call(FREETDS_LIB_PATH) do
    # Try the <major>.<minor> subdirectory for fat binary gems
    major_minor = RUBY_VERSION[/^(\d+\.\d+)/] or
      raise "Oops, can't extract the major/minor version from #{RUBY_VERSION.dump}"
    require "tiny_tds/#{major_minor}/tiny_tds"
  rescue LoadError
    require "tiny_tds/tiny_tds"
  end
end
