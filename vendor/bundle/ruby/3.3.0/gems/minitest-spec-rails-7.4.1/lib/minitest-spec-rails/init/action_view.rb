module MiniTestSpecRails
  module Init
    module ActionViewBehavior
      extend ActiveSupport::Concern

      included do
        class_attribute :_helper_class
        register_spec_type(/(Helper|View)( ?Test)?\z/, self)
        register_spec_type(self) { |desc| desc.is_a?(Class) && desc < self }
        extend Descriptions
      end

      module Descriptions
        def described_class
          determine_default_helper_class(name)
        end
      end
    end
  end
end

ActionView::TestCase.send :include, MiniTestSpecRails::Init::ActionViewBehavior
