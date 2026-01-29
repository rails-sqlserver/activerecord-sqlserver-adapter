ENV['RAILS_ENV'] ||= 'test'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __dir__)
require 'bundler/setup'
require 'rails/all'
Bundler.require(:default, Rails.env)
require 'minitest/focus'
require 'pry'

module Dummy
  class Application < ::Rails::Application
    # Basic Engine
    config.root = File.join __FILE__, '..'
    config.cache_store = :memory_store
    config.assets.enabled = false if Rails.version < '7.0.0'
    config.secret_token = '012345678901234567890123456789'
    config.active_support.test_order = :random
    # Mimic Test Environment Config.
    config.whiny_nils = true
    config.consider_all_requests_local = true
    config.action_controller.perform_caching = false
    config.action_dispatch.show_exceptions = false
    config.action_controller.allow_forgery_protection = false
    config.action_mailer.delivery_method = :test
    config.active_support.deprecation = :stderr
    config.allow_concurrency = true
    config.cache_classes = true
    config.dependency_loading = true
    config.preload_frameworks = true
    config.eager_load = true
    # Custom
    config.minitest_spec_rails.mini_shoulda = true
  end
end

Dummy::Application.initialize!
require 'rails/test_help'

# Avoids local NoMethodError: undefined method `split' for nil:NilClass
Rails.backtrace_cleaner.remove_silencers!
