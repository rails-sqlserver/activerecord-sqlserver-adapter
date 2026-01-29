module MiniTestSpecRails
  class Railtie < ::Rails::Railtie
    config.minitest_spec_rails = ActiveSupport::OrderedOptions.new
    config.minitest_spec_rails.mini_shoulda = false

    config.before_initialize do |_app|
      require 'active_support'
      require 'minitest-spec-rails/init/active_support'
      require 'minitest-spec-rails/parallelize'
      ActiveSupport.on_load(:action_cable) do
        require 'minitest-spec-rails/init/action_cable'
      end
      ActiveSupport.on_load(:action_controller) do
        require 'minitest-spec-rails/init/action_controller'
        require 'minitest-spec-rails/init/action_dispatch'
      end
      ActiveSupport.on_load(:action_mailer) do
        require 'minitest-spec-rails/init/action_mailer'
      end
      ActiveSupport.on_load(:active_job) do
        require 'minitest-spec-rails/init/active_job'
      end
    end

    initializer 'minitest-spec-rails.action_view', after: 'action_view.setup_action_pack', group: :all do |_app|
      Rails.application.config.to_prepare do
        ActiveSupport.on_load(:action_view) do
          require 'minitest-spec-rails/init/action_view'
        end
      end
    end

    initializer 'minitest-spec-rails.mini_shoulda', group: :all do |app|
      require 'minitest-spec-rails/init/mini_shoulda' if app.config.minitest_spec_rails.mini_shoulda
    end
  end
end
