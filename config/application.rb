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

    initializer 'xikolo-patches' do
      require 'ext/xikolo/common/paginate_with_retries'

      ::Xikolo.send :extend, Xikolo::Common::PaginateWithRetries
    end
  end

  def self.rake?
    @rake
  end

  def self.rake=(value)
    @rake = !!value
  end
end
