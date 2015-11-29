module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Version

        VERSION = File.read(File.expand_path("../../../../../VERSION", __FILE__)).chomp

      end
    end
  end
end
