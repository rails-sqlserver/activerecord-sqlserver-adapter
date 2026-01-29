require "rbconfig"
require "rake"
require "rake/clean"
require "rake/extensiontask"

SPEC = Gem::Specification.load(File.expand_path("../tiny_tds.gemspec", __FILE__))

CrossLibrary = Struct.new :platform, :openssl_config
CrossLibraries = [
  ["x64-mingw-ucrt", "mingw64"],
  ["x64-mingw32", "mingw64"],
  ["x86_64-linux-gnu", "linux-x86_64"],
  ["x86_64-linux-musl", "linux-x86_64"],
  ["aarch64-linux-gnu", "linux-aarch64"],
  ["aarch64-linux-musl", "linux-aarch64"]
].map do |platform, openssl_config|
  CrossLibrary.new platform, openssl_config
end

# Add our project specific files to clean for a rebuild
CLEAN.include FileList["{ext,lib}/**/*.{so,#{RbConfig::CONFIG["DLEXT"]},o}"],
  FileList["exe/*"]

# Clobber all our temp files and ports files including .install files
# and archives
CLOBBER.include FileList["tmp/**/*"],
  FileList["ports/**/*"].exclude(%r{^ports/archives})

Dir["tasks/*.rake"].sort.each { |f| load f }

Rake::ExtensionTask.new("tiny_tds", SPEC) do |ext|
  ext.lib_dir = "lib/tiny_tds"
  ext.cross_compile = true
  ext.cross_platform = CrossLibraries.map(&:platform)

  # Add dependent DLLs to the cross gems
  ext.cross_compiling do |spec|
    # The fat binary gem doesn't depend on the freetds package, since it bundles the library.
    spec.metadata.delete("msys2_mingw_dependencies")

    if /mingw/.match?(spec.platform.to_s)
      spec.files += [
        "ports/#{spec.platform}/bin/libsybdb-5.dll",
        "ports/#{spec.platform}/bin/defncopy.exe",
        "ports/#{spec.platform}/bin/tsql.exe"
      ]
    elsif /linux/.match?(spec.platform.to_s)
      spec.files += [
        "ports/#{spec.platform}/lib/libsybdb.so.5",
        "ports/#{spec.platform}/bin/defncopy",
        "ports/#{spec.platform}/bin/tsql"
      ]
    end
  end

  ext.cross_config_options += CrossLibraries.map do |xlib|
    {
      xlib.platform => [
        "--with-cross-build=#{xlib.platform}",
        "--with-openssl-platform=#{xlib.openssl_config}"
      ]
    }
  end
end

task build: [:clean, :compile]
task default: [:build, :test]

task :format do
  system("bundle exec standardrb --fix")
  system('astyle --options=astyle.conf "./ext/*.c" "./ext/*.h"')
end
