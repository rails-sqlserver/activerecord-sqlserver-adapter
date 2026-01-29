require_relative "../ext/tiny_tds/extconsts"

namespace :ports do
  libraries_to_compile = {
    openssl: OPENSSL_VERSION,
    libiconv: ICONV_VERSION,
    freetds: FREETDS_VERSION
  }

  desc "Notes the actual versions for the compiled ports into a file"
  task "version_file", [:gem_platform] do |_task, args|
    args.with_defaults(gem_platform: RbConfig::CONFIG["arch"])

    ports_version = {}

    libraries_to_compile.each do |library, version|
      ports_version[library] = version
    end

    ports_version[:platform] = args.gem_platform

    File.write(".ports_versions", ports_version)
  end
end
