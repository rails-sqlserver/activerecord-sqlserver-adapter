module ARTest
  module SQLServer
    module CoercedTest

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods

        def self.extended(base)
          base.class_eval do
            Array(coerced_tests).each do |method_name|
              undefine_and_puts(method_name)
            end
          end
        end

        def coerced_tests
          self.const_get(:COERCED_TESTS) rescue nil
        end

        def method_added(method)
          if coerced_tests && coerced_tests.include?(method)
            undefine_and_puts(method)
          end
        end

        def undefine_and_puts(method)
          result = undef_method(method) rescue nil
          STDOUT.puts("Info: Undefined coerced test: #{self.name}##{method}") unless result.blank?
        end

      end
    end
  end
end
