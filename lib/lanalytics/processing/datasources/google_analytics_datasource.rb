require 'net/ping'
require 'googleauth'
require 'google/apis/analytics_v3'
require 'google/apis/analyticsreporting_v4'
module Lanalytics
  module Processing
    module Datasources
      class GoogleAnalyticsDatasource < Datasource

        MIN_REPORT_DATE = Date.new(2005, 1, 1)
        AUTH_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly'

        attr_reader :client_email, :private_key, :view_id

        def initialize(ga_config)
          super(ga_config)
          setup
        end

        def setup
          if view_id.blank?
            raise 'Google Analytics view ID is not set. Plz have a look at the configuration ...'
          end
          if client_email.blank? || private_key.blank?
            raise 'Google Analytics credentials are not set. Plz have a look at the configuration ...'
          end

          credentials = Google::Auth::ServiceAccountCredentials.new token_credential_uri: Google::Auth::ServiceAccountCredentials::TOKEN_CRED_URI,
                                                                    audience: Google::Auth::ServiceAccountCredentials::TOKEN_CRED_URI,
                                                                    scope: AUTH_SCOPE,
                                                                    issuer: client_email,
                                                                    signing_key: OpenSSL::PKey::RSA.new(private_key)
          @reporting_client = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new
          @reporting_client.authorization = credentials

          @realtime_client = Google::Apis::AnalyticsV3::AnalyticsService.new
          @realtime_client.authorization = credentials

          @ping_client = Net::Ping::TCP.new URI.parse(@reporting_client.root_url).host, 80
        end

        def adoption_date
          @adoption_date ||= begin
            # Gets first day data was collected in configured view
            response = @reporting_client.batch_get_reports({report_requests: [{
              view_id: view_id.to_s,
              page_size: 1,
              date_ranges: [{
                start_date: MIN_REPORT_DATE,
                end_date: Date.today
              }],
              dimensions: [{ name: 'ga:date' }],
              metrics: [{ expression: 'ga:users' }],
              order_bys: [{ field_name: 'ga:date' }],
              hide_value_ranges: true
            }]}, {})

            rows = response.reports[0].data.rows
            rows.present? ? rows[0].dimensions[0].to_date : Date.today
          end
        end

        def exec
          return unless block_given?
          yield @reporting_client, @realtime_client
        end

        def ping
          @ping_client.ping?
        end

        def settings
          # Return all instance variables except the instance variable 'client'
          instance_values.symbolize_keys.except(:client)
        end

      end
    end
  end
end