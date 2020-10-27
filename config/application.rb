# frozen_string_literal: true

require_relative 'boot'

require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'

require 'bundler'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'telegraf/rails'

module Xikolo::Lanalytics
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.autoload_paths += %W(#{config.root}/lib)
    config.eager_load_paths += %W(#{config.root}/lib)

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.action_controller.default_protect_from_forgery = false

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.telegraf.rack.tags = {application: 'learnanalytics'}
    config.telegraf.sidekiq.tags = {application: 'learnanalytics'}

    initializer 'xikolo-patches' do
      require 'ext/xikolo/common/paginate_with_retries'

      ::Xikolo.send :extend, Xikolo::Common::PaginateWithRetries
    end

    # Restify: Do not wrap hashes with object-like accessors
    Restify::Processors::Json.indifferent_access = false

    # Register locations for loading application config
    require 'lanalytics/config'
    ::Lanalytics::Config.locations = [
      Rails.root.join('app/xikolo.yml'),
      ('/etc/xikolo.yml' unless Rails.env.test?),
      (::File.expand_path('~/.xikolo.yml') if !Rails.env.test? && ENV.key?('HOME')),
      Rails.root.join('config/xikolo.yml'),
      "/etc/xikolo.#{Rails.env}.yml",
      (::File.expand_path("~/.xikolo.#{Rails.env}.yml") if ENV.key?('HOME')),
      "config/xikolo.#{Rails.env}.yml",
    ].compact
  end

  def self.rake?
    @rake
  end

  def self.rake=(value)
    @rake = !!value
  end
end
