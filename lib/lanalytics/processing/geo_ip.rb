module Lanalytics
  module Processing
    class GeoIp
      include Singleton

      attr_reader :db

      def initialize
        @db = MaxMindDB.new('vendor/lib/GeoLite2-City.mmdb')
      end

      def self.lookup(user_ip)
        instance.db.lookup(user_ip)
      end
    end
  end
end
