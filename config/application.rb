# frozen_string_literal: true

require_relative 'boot'

# Require all patches before loading gems and application
Dir[File.expand_path('../lib/patches/**/*.rb', __dir__)].each {|f| require f }

require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'telegraf/rails'

module Lanalytics
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Auto and eager load library code
    config.autoload_paths += %W[#{config.root}/lib]
    config.eager_load_paths += %W[#{config.root}/lib]

    # When eager-loading, load the GeoIP database once to save memory.
    require 'geo_ip/lookup'
    config.eager_load_namespaces << GeoIP

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.action_controller.default_protect_from_forgery = false

    config.active_job.queue_adapter = :sidekiq

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Configure Telegraf event collection
    config.telegraf.tags = {application: 'learnanalytics'}

    # Register service URLs from services.yml in the Restify registry
    initializer 'restify-services' do |app|
      services = app.config_for(:services).fetch(:services, {})

      services.each do |service, location|
        Restify::Registry.store service.to_sym, location
      end

      Restify::Registry.store :xikolo, Lanalytics.config.bridge_api_url,
        headers: {'Authorization' => "Bearer #{app.secrets.bridge_api_token}"}
    end

    # Setup Sidekiq Redis connection as configured in config/sidekiq_redis.yml
    initializer 'sidekiq-connection' do |app|
      redis_config = app.config_for(:sidekiq_redis)

      # Optional: Redis Sentinel support
      # Both Sidekiq server and client do write operations, so we always need
      # to connect to the master.
      redis_config[:role] = 'master' if redis_config[:sentinels]

      ::Sidekiq.configure_server do |config|
        config.redis = redis_config
      end

      ::Sidekiq.configure_client do |config|
        config.redis = redis_config
      end
    end

    # We automatically configure the sidekiq-cron gem via a config/cron.yml file
    initializer :sidekiq_cron do |app|
      next unless Sidekiq.server?

      # By using an after_initialize callback, we make sure that Redis can be
      # configured properly before we try to store any cron job information.
      app.config.after_initialize do
        # rubocop:disable Rails/FindEach
        # `Sidekiq::Cron::Job.all` returns an array and not Active Record
        # relation, so `find_each` is not defined.
        Sidekiq::Cron::Job.all.each(&:destroy)
        # rubocop:enable Rails/FindEach
        Sidekiq::Cron::Job.load_from_hash! app.config_for(:cron) || {}
      end
    end

    # Restify: Do not wrap hashes with object-like accessors
    Restify::Processors::Json.indifferent_access = false

    # Load our custom Xikolo libs
    require 'xikolo'

    # Register locations for loading application config
    require 'lanalytics/config'
    ::Lanalytics::Config.locations = [
      Rails.root.join('app/xikolo.yml'),
      ('/etc/xikolo.yml' unless Rails.env.test?),
      Rails.root.join('config/xikolo.yml'),
      "/etc/xikolo.#{Rails.env}.yml",
      "config/xikolo.#{Rails.env}.yml",
    ].compact
  end
end
