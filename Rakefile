# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require_relative "test/support/paths_sqlserver"
require_relative "test/support/rake_helpers"

task test: ["test:dblib"]
task default: [:test]

namespace :test do
  ENV["ARCONN"] = "sqlserver"

  %w(dblib).each do |mode|
    Rake::TestTask.new(mode) do |t|
      t.libs = ARTest::SQLServer.test_load_paths
      t.test_files = test_files
      t.warning = !!ENV["WARNING"]
      t.verbose = false
    end
  end

  task "dblib:env" do
    ENV["ARCONN_MODE"] = "dblib"
  end
end

task "test:dblib" => "test:dblib:env"

namespace :profile do
  ["dblib"].each do |mode|
    namespace mode.to_sym do
      Dir.glob("test/profile/*_profile_case.rb").sort.each do |test_file|
        profile_case = File.basename(test_file).sub("_profile_case.rb", "")
        Rake::TestTask.new(profile_case) do |t|
          t.libs = ARTest::SQLServer.test_load_paths
          t.test_files = [test_file]
          t.verbose = true
        end
      end
    end
  end
end
