require 'link_header'

namespace :lanalytics do
  desc 'Create custom dimensions and metrics for the configured Google Analytics account'
  task sync_ga_custom_definitions: :environment do
    datasource = Lanalytics::Processing::DatasourceManager.datasource('google_analytics')
    if datasource.nil?
      Rails.logger.info 'GoogleAnalyticsDatasource is not configured'
      next
    end

    datasource.sync_custom_definitions
  end
end
