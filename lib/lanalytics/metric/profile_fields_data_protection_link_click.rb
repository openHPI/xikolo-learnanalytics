# frozen_string_literal: true

module Lanalytics
  module Metric
    class ProfileFieldsDataProtectionLinkClick < LinkTrackingEventsElasticMetric
      description 'Check if a user has clicked on the ' \
                  'profile_fields_data_protection_link (A/B test)'

      required_parameter :course_id, :user_id

      exec do |params|
        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {match: {tracking_type: 'profile_fields_data_protection_link'}},
                {match: {course_id: params[:course_id]}},
                {match: {user_id: params[:user_id]}},
              ],
            },
          },
        }

        result = datasource.exec do |client|
          client.search(index: datasource.index, body:)
        end

        {clicked: result.dig('hits', 'total', 'value').to_i.positive?}
      end
    end
  end
end
