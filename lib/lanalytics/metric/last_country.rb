# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module Lanalytics
  module Metric
    class LastCountry < ExpEventsElasticMetric
      description 'The last country from which a user accessed a course.'

      required_parameter :course_id, :user_id

      exec do |params|
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 1,
            query: {
              bool: {
                must: [
                  {exists: {field: 'in_context.user_location_country_code'}},
                ] + all_filters(params[:user_id], params[:course_id], nil),
              },
            },
            sort: {
              timestamp: {
                order: 'desc',
              },
            },
          }
        end

        {
          code: result.dig(
            'hits',
            'hits',
            0,
            '_source',
            'in_context',
            'user_location_country_code',
          ),
        }
      end
    end
  end
end
# rubocop:enable all
