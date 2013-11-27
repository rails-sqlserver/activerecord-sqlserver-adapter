module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module SupportedVersions
        SUPPORTED_VERSIONS = [9, 10, 11] # 2005, 2008, 2012

        # Raises a NotImplementedError if the product_version is not supported.
        def ensure_supported_version(product_version, database_version)
          unless supports_version?(product_version)
            raise NotImplementedError, "Currently, only #{SUPPORTED_VERSIONS.to_sentence} are supported. We got back #{database_version}."
          end
        end

        # Returns true if the product version is supported.
        def supports_version?(product_version)
          SUPPORTED_VERSIONS.include?(product_version.to_i)
        end
      end
    end
  end
end
