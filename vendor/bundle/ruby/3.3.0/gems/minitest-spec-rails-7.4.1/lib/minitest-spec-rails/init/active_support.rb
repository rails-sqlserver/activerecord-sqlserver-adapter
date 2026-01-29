module MiniTestSpecRails
  module Init
    module ActiveSupportBehavior
      extend ActiveSupport::Concern

      included do
        extend Minitest::Spec::DSL
        include MiniTestSpecRails::DSL
        include ActiveSupport::Testing::ConstantLookup
        extend Descriptions
        register_spec_type(self) { |_desc| true }
      end

      module Descriptions
        def described_class
          determine_constant_from_test_name(name) do |constant|
            constant.is_a?(Class)
          end
        end
      end

      if Minitest::VERSION < '5.3.3'
        def initialize(*args)
          Thread.current[:current_spec] = self
          super
        end
      end
    end
  end
end

ActiveSupport::TestCase.send :include, MiniTestSpecRails::Init::ActiveSupportBehavior
