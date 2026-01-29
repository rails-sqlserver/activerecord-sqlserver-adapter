module MiniTestSpecRails
  module Init
    module ActionMailerBehavior
      extend ActiveSupport::Concern

      included do
        register_spec_type(self) { |desc| desc.is_a?(Class) && desc < ActionMailer::Base }
        register_spec_type(/Mailer( ?Test)?\z/, self)
        register_spec_type(self) { |desc| desc.is_a?(Class) && desc < self }
        extend Descriptions
      end

      module Descriptions
        def described_class
          determine_default_mailer(name)
        end
      end
    end
  end
end

ActionMailer::TestCase.send :include, MiniTestSpecRails::Init::ActionMailerBehavior
