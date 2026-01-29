require_relative "version"
require_relative "gem"
require "shellwords"

module TinyTds
  class Bin
    attr_reader :name

    class << self
      def exe(name, *args)
        bin = new(name)
        puts bin.info unless args.any? { |x| x == "-q" }
        bin.run(*args)
      end
    end

    def initialize(name)
      @root = Gem.root_path
      @exts = (ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]) | [".exe"]

      @name = name
      @binstub = find_bin
      @exefile = find_exe
    end

    def run(*args)
      with_ports_paths do
        return nil unless path
        Kernel.system Shellwords.join(args.unshift(path))
        $CHILD_STATUS.to_i
      end
    end

    def path
      @path ||= (@exefile && File.exist?(@exefile)) ? @exefile : which
    end

    def info
      "[TinyTds][v#{TinyTds::VERSION}][#{name}]: #{path}"
    end

    private

    def search_paths
      ENV["PATH"].split File::PATH_SEPARATOR
    end

    def with_ports_paths
      old_path = ENV["PATH"]

      begin
        ENV["PATH"] = [
          Gem.ports_bin_and_lib_paths,
          old_path
        ].flatten.join File::PATH_SEPARATOR

        yield if block_given?
      ensure
        ENV["PATH"] = old_path
      end
    end

    def find_bin
      File.join @root, "bin", name
    end

    def find_exe
      Gem.ports_bin_and_lib_paths.each do |bin|
        @exts.each do |ext|
          f = File.join bin, "#{name}#{ext}"
          return f if File.exist?(f)
        end
      end
      nil
    end

    def which
      search_paths.each do |path|
        @exts.each do |ext|
          exe = File.expand_path File.join(path, "#{name}#{ext}"), @root
          next if exe == @binstub
          next unless File.executable?(exe)

          return exe
        end
      end
      nil
    end
  end
end
