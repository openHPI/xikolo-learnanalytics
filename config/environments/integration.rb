Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

  # Do eager load code on boot. This allows us to catch some errors at boot time instead
  # of test time.
  config.eager_load = true

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_assets = true
  config.static_cache_control = 'public, max-age=3600'

  # Match production environment but report errors
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # cache
  config.action_controller.perform_caching = true
  config.cache_store = :redis_store, 'redis://127.0.0.1/3', {namespace: 'integration', expires_in: 10.minutes}

  config.log_level = :info
end
