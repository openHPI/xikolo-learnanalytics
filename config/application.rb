require File.expand_path('../boot', __FILE__)

require 'rails/all'
#File.expand_path('../lib/lanalytics/experience_api/statement', __FILE__)
#require '../lanalytics/experience_api/statement'

#require 'rails'

#%w(
#  neo4j
#  action_controller
#  action_mailer
#  sprockets
#).each do |framework|
#  begin
#    require "#{framework}/railtie"
#  rescue LoadError
#  end
#end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lanalytics
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    #config.neo4j.session_type = :server_db
    #config.neo4j.session_path = ENV['GRAPHENEDB_URL'] || 'http://localhost:7474'

    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')

    Timezone::Configure.begin do |c|
      # geonames.org username
      c.username = 'openhpi'
    end

  end


  def self.rake?
    !!@rake
  end

  def self.rake=(value)
    @rake = !!value
  end

end
