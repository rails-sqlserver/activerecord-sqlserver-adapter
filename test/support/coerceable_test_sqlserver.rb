module ARTest
  module SQLServer
    module CoerceableTest

      extend ActiveSupport::Concern

      included do
        cattr_accessor :coerced_tests, instance_accessor: false
        self.coerced_tests = []
      end

      module ClassMethods

        def coerce_tests(*methods)
          methods.each do |method|
            self.coerced_tests.push(method)
            coerced_test_warning(method)
          end
        end

        def coerce_test!(method)
          coerced_test_warning(method)
        end

        def coerce_all_tests!
          once = false
          instance_methods(false).each do |method|
            next unless method.to_s =~ /\Atest/
            undef_method(method)
            once = true
          end
          STDOUT.puts "Info: Undefined all tests: #{self.name}"
        end

        def method_added(method)
          coerced_test_warning(method) if coerced_tests.include?(method.to_sym)
        end

        private

        def coerced_test_warning(method)
          result = undef_method(method) rescue nil
          STDOUT.puts "Info: Undefined coerced test: #{self.name}##{method}" unless result.blank?
        end

      end

    end
  end
end
