module MiniTestSpecRails
  module Init
    module MiniShouldaBehavior
      extend ActiveSupport::Concern

      included do
        class << self
          alias_method :context, :describe
          alias_method :should, :it
        end
        extend ClassMethods
      end

      module ClassMethods
        def should_eventually(desc)
          it("should eventually #{desc}") { skip("Should eventually #{desc}") }
        end
      end
    end
  end
end

ActiveSupport::TestCase.send :include, MiniTestSpecRails::Init::MiniShouldaBehavior
