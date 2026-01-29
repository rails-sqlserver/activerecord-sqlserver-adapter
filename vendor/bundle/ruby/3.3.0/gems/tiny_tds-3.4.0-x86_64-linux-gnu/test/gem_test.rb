require "test_helper"
require "tiny_tds/gem"

class GemTest < Minitest::Spec
  gem_root ||= File.expand_path "../..", __FILE__

  describe TinyTds::Gem do
    # We're going to muck with some system globals so lets make sure
    # they get set back later
    original_pwd = Dir.pwd

    after do
      Dir.chdir original_pwd
    end

    describe "#root_path" do
      let(:root_path) { TinyTds::Gem.root_path }

      it "should be the root path" do
        _(root_path).must_equal gem_root
      end

      it "should be the root path no matter the cwd" do
        Dir.chdir "/"

        _(root_path).must_equal gem_root
      end
    end

    describe "#ports_root_path" do
      let(:ports_root_path) { TinyTds::Gem.ports_root_path }

      it "should be the ports path" do
        _(ports_root_path).must_equal File.join(gem_root, "ports")
      end

      it "should be the ports path no matter the cwd" do
        Dir.chdir "/"

        _(ports_root_path).must_equal File.join(gem_root, "ports")
      end
    end

    describe "#ports_bin_and_lib_paths" do
      let(:ports_bin_and_lib_paths) { TinyTds::Gem.ports_bin_and_lib_paths }

      describe "when the ports directories exist" do
        let(:fake_bin_and_lib_path) do
          ports_host_root = File.join(gem_root, "ports", "x86_64-unknown")
          ["bin", "lib"].map do |p|
            File.join(ports_host_root, p)
          end
        end

        before do
          fake_bin_and_lib_path.each do |path|
            FileUtils.mkdir_p(path)
          end
        end

        after do
          FileUtils.remove_entry_secure(
            File.join(gem_root, "ports", "x86_64-unknown"), true
          )
        end

        it "should return all the bin directories" do
          fake_platform = Gem::Platform.new("x86_64-unknown")

          Gem::Platform.stub(:local, fake_platform) do
            _(ports_bin_and_lib_paths.sort).must_equal fake_bin_and_lib_path.sort

            # should return the same regardless of path
            Dir.chdir "/"
            _(ports_bin_and_lib_paths.sort).must_equal fake_bin_and_lib_path.sort
          end
        end
      end

      describe "when the ports directories are missing" do
        it "should return no directories" do
          fake_platform = Gem::Platform.new("x86_64-unknown")

          Gem::Platform.stub(:local, fake_platform) do
            _(ports_bin_and_lib_paths).must_be_empty

            # should be empty regardless of path
            Dir.chdir "/"
            _(ports_bin_and_lib_paths).must_be_empty
          end
        end
      end
    end
  end
end
