module MiniTestSpecRails
  module Init
    module ActionControllerBehavior
      extend ActiveSupport::Concern

      included do
        extend Descriptions
        register_spec_type(self) { |desc| desc.is_a?(Class) && desc < ActionController::Metal }
        register_spec_type(/Controller( ?Test)?\z/, self)
        register_spec_type(self) { |desc| desc.is_a?(Class) && desc < self }
      end

      module Descriptions
        def described_class
          determine_default_controller_class(name)
        end
      end
    end
  end
end

ActionController::TestCase.send :include, MiniTestSpecRails::Init::ActionControllerBehavior
