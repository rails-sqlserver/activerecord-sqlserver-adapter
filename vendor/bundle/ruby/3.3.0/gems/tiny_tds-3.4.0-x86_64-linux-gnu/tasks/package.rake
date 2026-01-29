require "rubygems/package_task"

Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end
