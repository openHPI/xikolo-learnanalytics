require 'net/ping'
require 'googleauth'
require 'google/apis/analytics_v3'
require 'google/apis/analyticsreporting_v4'
module Lanalytics
  module Processing
    module Datasources
      class GoogleAnalyticsDatasource < Datasource

        MIN_REPORT_DATE = Date.new(2005, 1, 1)
        AUTH_SCOPES = [
          'https://www.googleapis.com/auth/analytics.readonly',
          'https://www.googleapis.com/auth/analytics.edit'
        ]

        attr_reader :account_id, :tracking_id, :view_id, :client_email, :private_key

        def initialize(ga_config)
          super(ga_config)
          setup
        end

        def setup
          if account_id.blank?
            raise 'Google Analytics account ID is not set. Plz have a look at the configuration ...'
          end
          if tracking_id.blank?
            raise 'Google Analytics tracking ID is not set. Plz have a look at the configuration ...'
          end
          if view_id.blank?
            raise 'Google Analytics view ID is not set. Plz have a look at the configuration ...'
          end
          if client_email.blank? || private_key.blank?
            raise 'Google Analytics credentials are not set. Plz have a look at the configuration ...'
          end

          credentials = Google::Auth::ServiceAccountCredentials.new token_credential_uri: Google::Auth::ServiceAccountCredentials::TOKEN_CRED_URI,
                                                                    audience: Google::Auth::ServiceAccountCredentials::TOKEN_CRED_URI,
                                                                    scope: AUTH_SCOPES,
                                                                    issuer: client_email,
                                                                    signing_key: OpenSSL::PKey::RSA.new(private_key)

          # Used for requesting custom reports on aggregated data
          @reporting_client = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new
          @reporting_client.authorization = credentials

          # Used to retrieve realtime data and configuration of Google Analytics
          @analyticsv3_client = Google::Apis::AnalyticsV3::AnalyticsService.new
          @analyticsv3_client.authorization = credentials

          @ping_client = Net::Ping::TCP.new URI.parse(@reporting_client.root_url).host, 80

          sync_custom_definitions
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

        def custom_dimensions
          [
            { name: :course_id,  scope: :hit },
            { name: :item_id, scope: :hit },
            { name: :quiz_type, scope: :hit },
            { name: :section_id, scope: :hit },
            { name: :question_id, scope: :hit },
            { name: :platform, scope: :session },
            { name: :platform_version, scope: :session },
            { name: :runtime, scope: :session },
            { name: :runtime_version, scope: :session },
            { name: :device, scope: :session }
          ]
        end

        def custom_metrics
          [
            {name: :points_percentage, scope: :hit, type: :integer },
            {name: :quiz_attempt, scope: :hit, type: :integer },
            {name: :quiz_needed_time, scope: :hit, type: :integer },
            {name: :video_time, scope: :hit, type: :integer }
          ]
        end

        def custom_dimension_index(name)
          index = custom_dimensions.find_index{ |item| item[:name] == name }
          if index.nil?
            raise 'Invalid custom dimension'
          end
          index + 1
        end

        def custom_metric_index(name)
          index = custom_metrics.find_index{ |item| item[:name] == name }
          if index.nil?
            raise 'Invalid custom metric'
          end
          index + 1
        end

        def exec
          return unless block_given?
          yield @reporting_client, @analyticsv3_client
        end

        def ping
          @ping_client.ping?
        end

        def settings
          # Return all instance variables except the client instance variable
          instance_values.symbolize_keys.except(:reporting_client, :analyticsv3_client, :ping_client)
        end

        private

        def sync_custom_definitions
          sync_custom_dimensions
          sync_custom_metrics
        end

        def sync_custom_dimensions
          existing_dimensions = @analyticsv3_client.list_custom_dimensions(account_id, tracking_id).items
          custom_dimensions.each_with_index do |options, index|
            dimension = Google::Apis::AnalyticsV3::CustomDimension.new active: true,
                                                                       index: index + 1,
                                                                       name: options[:name].to_s,
                                                                       scope: options[:scope].to_s.upcase
            existing_dimension = existing_dimensions.find{ |item| item.index == dimension.index }
            if existing_dimension.nil?
              @analyticsv3_client.insert_custom_dimension account_id, tracking_id, dimension
            elsif existing_dimension.name != dimension.name || existing_dimension.scope != dimension.scope || !existing_dimension.active
              @analyticsv3_client.update_custom_dimension account_id, tracking_id, existing_dimension.id, dimension
            end
          end
        end

        def sync_custom_metrics
          existing_metrics = @analyticsv3_client.list_custom_metrics(account_id, tracking_id).items
          custom_metrics.each_with_index do |options, index|
            metric = Google::Apis::AnalyticsV3::CustomMetric.new active: true,
                                                                 index: index + 1,
                                                                 name: options[:name].to_s,
                                                                 scope: options[:scope].to_s.upcase,
                                                                 type: options[:type].to_s.upcase
            existing_metric = existing_metrics.find{ |item| item.index == metric.index }
            if existing_metric.nil?
              @analyticsv3_client.insert_custom_metric account_id, tracking_id, metric
            elsif existing_metric.name != metric.name || existing_metric.scope != metric.scope || existing_metric.type != metric.type || !existing_metric.active
              @analyticsv3_client.update_custom_metric account_id, tracking_id, existing_metric.id, metric
            end
          end
        end

      end
    end
  end
end