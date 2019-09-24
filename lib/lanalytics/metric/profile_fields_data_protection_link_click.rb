module Lanalytics
  module Metric
    class ProfileFieldsDataProtectionLinkClick < ExpApiMetric

      description 'Check if a user has clicked on the profile_fields_data_protection_link (A/B test)'

      required_parameter :course_id, :user_id

      exec do |params|
        body = {
          size: 0,
          query: {
            bool: {
              must: [
                { match: { tracking_type: 'profile_fields_data_protection_link' } },
                { match: { course_id: params[:course_id] } },
                { match: { user_id: params[:user_id] } }
              ]
            }
          }
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: body
        end

        { clicked: result.dig('hits', 'total').to_i.positive? }
      end

    end
  end
end
