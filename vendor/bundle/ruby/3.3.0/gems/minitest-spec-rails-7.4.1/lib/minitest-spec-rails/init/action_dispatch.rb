module MiniTestSpecRails
  module Init
    module ActionDispatchBehavior
      extend ActiveSupport::Concern

      included do
        register_spec_type(/(Acceptance|Integration) ?Test\z/, self)
        register_spec_type(self) { |desc| desc.is_a?(Class) && desc < self }
      end
    end
  end
end

ActionDispatch::IntegrationTest.send :include, MiniTestSpecRails::Init::ActionDispatchBehavior
