# frozen_string_literal: true

module Lanalytics
  module Metric
    class ReferrerCount < LinkTrackingEventsElasticMetric
      description 'Counts all referrers'

      optional_parameter :course_id

      exec do |params|
        result = datasource.exec do |client|
          body = {
            size: 0,
            aggregations: {
              referrer: {
                value_count: {
                  field: 'referrer',
                },
              },
            },
          }

          if params[:course_id].present?
            body[:query] = {
              bool: {
                must: [
                  {match: {'course_id' => params[:course_id]}}
                ],
              },
            }
          end

          client.search(index: datasource.index, body:)
        end
        {count: result['aggregations']['referrer']['value']}
      end
    end
  end
end
