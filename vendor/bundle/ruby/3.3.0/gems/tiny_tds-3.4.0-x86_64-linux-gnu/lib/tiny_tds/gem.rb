module TinyTds
  module Gem
    class << self
      def root_path
        File.expand_path "../../..", __FILE__
      end

      def ports_root_path
        File.join(root_path, "ports")
      end

      def ports_bin_and_lib_paths
        Dir.glob(File.join(ports_root_path, "#{gem_platform.cpu}-#{gem_platform.os}*", "{bin,lib}"))
      end

      private

      def gem_platform
        ::Gem::Platform.local
      end
    end
  end
end
