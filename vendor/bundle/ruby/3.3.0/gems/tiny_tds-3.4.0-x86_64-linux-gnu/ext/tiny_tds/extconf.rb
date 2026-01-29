require "mkmf"
require_relative "extconsts"

if ENV["MAINTAINER_MODE"]
  warn "Maintainer mode enabled."
  $CFLAGS << # standard:disable Style/GlobalVars
    " -Wall" \
    " -ggdb" \
    " -DDEBUG" \
    " -pedantic"
  $LDFLAGS << # standard:disable Style/GlobalVars
    " -ggdb"
end

if (gem_platform = with_config("cross-build"))
  require "mini_portile2"

  openssl_platform = with_config("openssl-platform")

  class BuildRecipe < MiniPortile
    attr_accessor :gem_platform

    def initialize(name, version, files)
      super(name, version)
      self.files = files
      rootdir = File.expand_path("../../..", __FILE__)
      self.target = File.join(rootdir, "ports")
      self.patch_files = Dir[File.join("patches", self.name, self.version, "*.patch")].sort
    end

    # this will yield all ports into the same directory, making our path configuration for the linker easier
    def port_path
      "#{@target}/#{gem_platform}"
    end

    def cook_and_activate
      checkpoint = File.join(target, "#{name}-#{version}-#{gem_platform}.installed")

      unless File.exist?(checkpoint)
        cook
        FileUtils.touch checkpoint
      end

      activate
      self
    end
  end

  openssl_recipe = BuildRecipe.new("openssl", OPENSSL_VERSION, [OPENSSL_SOURCE_URI]).tap do |recipe|
    class << recipe
      attr_accessor :openssl_platform

      def configure
        envs = []
        envs << "CFLAGS=-DDSO_WIN32 -DOPENSSL_THREADS" if MiniPortile.windows?
        envs << "CFLAGS=-fPIC -DOPENSSL_THREADS" if MiniPortile.linux?
        execute("configure", ["env", *envs, "./Configure", openssl_platform, "threads", "-static", "CROSS_COMPILE=#{host}-", configure_prefix, "--libdir=lib"], altlog: "config.log")
      end

      def compile
        execute("compile", "#{make_cmd} build_libs")
      end

      def install
        execute("install", "#{make_cmd} install_dev")
      end
    end

    recipe.gem_platform = gem_platform
    recipe.openssl_platform = openssl_platform
    recipe.cook_and_activate
  end

  libiconv_recipe = BuildRecipe.new("libiconv", ICONV_VERSION, [ICONV_SOURCE_URI]).tap do |recipe|
    recipe.configure_options << "CFLAGS=-fPIC" if MiniPortile.linux?
    recipe.gem_platform = gem_platform

    recipe.cook_and_activate
  end

  # remove the ".la" files, otherwise libtool starts to complain when linking into FreeTDS
  Dir.glob(File.join(libiconv_recipe.path, "lib", "**", "*.la")).each do |la_file|
    File.delete(la_file)
  end

  freetds_recipe = BuildRecipe.new("freetds", FREETDS_VERSION, [FREETDS_SOURCE_URI]).tap do |recipe|
    class << recipe
      def configure_defaults
        [
          "--host=#{@host}",
          "--enable-shared",
          "--disable-static",
          "--disable-odbc"
        ]
      end
    end

    # i am not 100% what is going on behind the scenes
    # it seems that FreeTDS build system prefers OPENSSL_CFLAGS and OPENSSL_LIBS
    # but the linker still relies on LIBS and CPPFLAGS
    # removing one or the other leads to build failures in any case of FreeTDS
    if MiniPortile.linux?
      recipe.configure_options << "CFLAGS=-fPIC"
    elsif MiniPortile.windows?
      recipe.configure_options << "--enable-sspi"
    end

    # pass an additional runtime path to the linker so defncopy and tsql can find our shared sybdb
    recipe.configure_options << "LDFLAGS=-L#{openssl_recipe.path}/lib #{"-Wl,-rpath='$$ORIGIN/../lib'" if MiniPortile.linux?}"
    recipe.configure_options << "LIBS=-liconv -lssl -lcrypto #{"-lwsock32 -lgdi32 -lws2_32 -lcrypt32" if MiniPortile.windows?} #{"-ldl -lpthread" if MiniPortile.linux?}"
    recipe.configure_options << "CPPFLAGS=-I#{openssl_recipe.path}/include"

    recipe.configure_options << "OPENSSL_CFLAGS=-L#{openssl_recipe.path}/lib"
    recipe.configure_options << "OPENSSL_LIBS=-lssl -lcrypto #{"-lwsock32 -lgdi32 -lws2_32 -lcrypt32" if MiniPortile.windows?} #{"-ldl -lpthread" if MiniPortile.linux?}"

    recipe.configure_options << "--with-openssl=#{openssl_recipe.path}"
    recipe.configure_options << "--with-libiconv-prefix=#{libiconv_recipe.path}"
    recipe.configure_options << "--sysconfdir=C:/Sites" if MiniPortile.windows?

    recipe.gem_platform = gem_platform
    recipe.cook_and_activate
  end

  # enable relative path to later load the FreeTDS shared library
  $LDFLAGS << " '-Wl,-rpath=$$ORIGIN/../../../ports/#{gem_platform}/lib'" # standard:disable Style/GlobalVars

  dir_config("freetds", "#{freetds_recipe.path}/include", "#{freetds_recipe.path}/lib")
else
  # Make sure to check the ports path for the configured host
  architecture = RbConfig::CONFIG["arch"]

  project_dir = File.expand_path("../../..", __FILE__)
  freetds_ports_dir = File.join(project_dir, "ports", architecture, "freetds", FREETDS_VERSION)
  freetds_ports_dir = File.expand_path(freetds_ports_dir)

  # Add all the special path searching from the original tiny_tds build
  # order is important here! First in, first searched.
  DIRS = %w[
    /opt/local
    /usr/local
  ]

  if /darwin/i.match?(RbConfig::CONFIG["host_os"])
    # Ruby below 2.7 seems to label the host CPU on Apple Silicon as aarch64
    # 2.7 and above print is as ARM64
    target_host_cpu = (Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.7")) ? "aarch64" : "arm64"

    if RbConfig::CONFIG["host_cpu"] == target_host_cpu
      # Homebrew on Apple Silicon installs into /opt/hombrew
      # https://docs.brew.sh/Installation
      # On Intel Macs, it is /usr/local, so no changes necessary to DIRS
      DIRS.unshift("/opt/homebrew")
    end
  end

  if ENV["RI_DEVKIT"] && ENV["MINGW_PREFIX"] # RubyInstaller Support
    DIRS.unshift(File.join(ENV["RI_DEVKIT"], ENV["MINGW_PREFIX"]))
  end

  # Add the ports directory if it exists for local developer builds
  DIRS.unshift(freetds_ports_dir) if File.directory?(freetds_ports_dir)

  # Grab freetds environment variable for use by people on services like
  # Heroku who they can't easily use bundler config to set directories
  DIRS.unshift(ENV["FREETDS_DIR"]) if ENV.has_key?("FREETDS_DIR")

  # Add the search paths for freetds configured above
  ldirs = DIRS.flat_map do |path|
    ldir = "#{path}/lib"
    [ldir, "#{ldir}/freetds"]
  end

  idirs = DIRS.flat_map do |path|
    idir = "#{path}/include"
    [idir, "#{idir}/freetds"]
  end

  puts "looking for freetds headers in the following directories:\n#{idirs.map { |a| " - #{a}\n" }.join}"
  puts "looking for freetds library in the following directories:\n#{ldirs.map { |a| " - #{a}\n" }.join}"
  dir_config("freetds", idirs, ldirs)
end

find_header("sybfront.h") or abort "Can't find the 'sybfront.h' header"
find_header("sybdb.h") or abort "Can't find the 'sybdb.h' header"

unless have_library("sybdb", "dbanydatecrack")
  abort "Failed! Do you have FreeTDS 1.0.0 or higher installed?"
end

create_makefile("tiny_tds/tiny_tds")
