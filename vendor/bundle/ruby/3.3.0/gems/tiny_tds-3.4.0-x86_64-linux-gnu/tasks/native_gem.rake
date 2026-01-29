CrossLibraries.each do |xlib|
  platform = xlib.platform

  desc "Build fat binary gem for platform #{platform}"
  task "gem:native:#{platform}" do
    require "rake_compiler_dock"

    RakeCompilerDock.sh <<-EOT, platform: platform
			bundle install &&
			rake native:#{platform} pkg/#{SPEC.full_name}-#{platform}.gem MAKEOPTS=-j`nproc` RUBY_CC_VERSION=#{RakeCompilerDock.set_ruby_cc_version("~> 3.0", "~> 4.0")} MAKEFLAGS="V=1"
    EOT
  end

  desc "Build the native binary gems"
  multitask "gem:native" => "gem:native:#{platform}"
end
