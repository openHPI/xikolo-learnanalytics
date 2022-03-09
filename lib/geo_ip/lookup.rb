# frozen_string_literal: true

module GeoIP
  extend ActiveSupport::Autoload

  # Eager load for saving memory, configured for production and integration.
  def self.eager_load!
    super
    Lookup.instance
  end

  class Lookup
    include Singleton

    attr_reader :db

    def initialize
      # Ensure that you have a fresh version of the MaxMind GeoLite2 Database
      # located in vendor/lib/geo_ip/GeoLite2-Country.
      # See https://dev.maxmind.com/geoip/geolite2-free-geolocation-data
      @db = MaxMindDB.new('vendor/lib/geo_ip/GeoLite2-City/GeoLite2-City.mmdb')
    end

    def self.resolve(user_ip)
      instance.db.lookup(user_ip)
    end
  end
end
