# frozen_string_literal: true

module Lanalytics
  module Metric
    class ObjectiveSelectionDismissals < ExpEventsElasticMetric
      description <<~DOC
        Number of objectives selection dismissals by type (modal/infobox) and number of occurrences where both were dismissed.
      DOC

      optional_parameter :course_id, :user_id

      exec do |params|
        course_id = params[:course_id]
        user_id = params[:user_id]

        result = datasource.exec do |client|
          query_must = []
          query_must << {match: {'user.resource_uuid' => user_id}} if user_id.present?

          query_must << {match: {'in_context.context_id' => course_id}} if course_id.present?

          query_should = [
            {match: {'verb' => 'dismissed_objectives_modal'}},
            {match: {'verb' => 'dismissed_objectives_infobox'}},
          ]

          body = {
            size: 0,
            query: {
              bool: {
                must: query_must,
                filter: {
                  bool: {
                    should: query_should,
                  },
                },
              },
            },
            aggs: {
              distinct_user_count: {
                cardinality: {
                  field: 'user.resource_uuid',
                },
              },
              grouped_by_verb: {
                terms: {field: 'verb'},
              },
              grouped_by_user: {
                terms: {
                  field: 'user.resource_uuid',
                  order: {_count: 'desc'},
                },
                aggs: {
                  with_two_dismissals: {
                    bucket_selector: {
                      buckets_path: {
                        dismissals_count: '_count',
                      },
                      script: 'params.dismissals_count == 2',
                    },
                  },
                },
              },
            },
          }

          client.search(index: datasource.index, body:)
        end

        {
          # Count users with dismissed modal or infobox
          users_dismissed_selection: result.dig('aggregations', 'distinct_user_count', 'value'),
          # Count dismissals by type
          dismissed_by_type: result.dig('aggregations', 'grouped_by_verb', 'buckets')&.each_with_object({}) do |e, h|
            h[e['key']] = e['doc_count']
          end,
          # Count if both the modal and infobox were dismissed
          both_dismissed_count: result.dig('aggregations', 'grouped_by_user', 'buckets')&.size,
        }
      end
    end
  end
end
