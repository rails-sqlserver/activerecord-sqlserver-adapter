module ARTest
  module SQLServer
    module CoerceableTest

      extend ActiveSupport::Concern

      included do
        cattr_accessor :coerced_tests, instance_accessor: false
        self.coerced_tests = []
      end

      module ClassMethods

        def coerce_tests(*names)
          names.each do |n|
            self.coerced_tests.push(n)
            coerce_test!(n)
          end
        end

        def coerce_test!(method)
          coerced_test_warning(method)
        end

        def coerce_all_tests!
          instance_methods(false).each { |method| coerce_test!(method) if method.to_s =~ /\Atest/ }
        end

        def method_added(method)
          coerced_test_warning(method) if coerced_tests.include?(method.to_sym)
        end

        private

        def coerced_test_warning(method)
          result = undef_method(method) rescue nil
          STDOUT.puts("Info: Undefined coerced test: #{self.name}##{method}") unless result.blank?
        end

      end

    end
  end
end
