# frozen_string_literal: true

module ARTest
  module SQLServer
    module CoerceableTest
      extend ActiveSupport::Concern

      included do
        cattr_accessor :coerced_tests, instance_accessor: false
        self.coerced_tests = []
      end

      module ClassMethods
        def coerce_tests!(*methods)
          methods.each do |method|
            coerced_tests.push(method)
            coerced_test_warning(method)
          end
        end

        def coerce_all_tests!
          instance_methods(false).each do |method|
            next unless method.to_s.start_with?("test")

            undef_method(method)
          end
          $stdout.puts "🙉 🙈 🙊  Undefined all tests: #{name}"
        end

        private

        def coerced_test_warning(test_to_coerce)
          method = if test_to_coerce.is_a?(Regexp)
            instance_methods(false).select { |m| m =~ test_to_coerce }
          else
            test_to_coerce
          end

          Array(method).each do |m|
            result = if m && method_defined?(m)
              alias_method("original_#{test_to_coerce.inspect.tr('/\:"', "")}", m)
              undef_method(m)
            end

            if result.blank?
              $stdout.puts "🐳  Unfound coerced test: #{name}##{m}"
            else
              $stdout.puts "🐵  Undefined coerced test: #{name}##{m}"
            end
          end
        end
      end
    end
  end
end
