# frozen_string_literal: true

module Lanalytics
  module Metric
    class PinboardSummary < ExpEventsElasticMetric
      description 'Returns the total number of events for the different pinboard activities.'

      optional_parameter :user_id, :course_id

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: all_filters(user_id, course_id, nil) + [
                  {bool: {
                    minimum_should_match: 1,
                    should: [
                      {match: {'verb' => 'asked_question'}},
                      {match: {'verb' => 'answered_question'}},
                      {match: {'verb' => 'commented'}},
                      {match: {'verb' => 'visited_pinboard'}},
                      {match: {'verb' => 'visited_question'}}
                    ]
                  }}
                ],
              }
            },
            aggs: {
              by_verb: {
                terms: {
                  field: 'verb',
                  order: {_count: 'desc'},
                  size: 5
                }
              }
            }
          }
        end

        result.dig('aggregations', 'by_verb', 'buckets')&.each_with_object({}) do |b, h|
          h[b['key']] = b['doc_count']
        end
      end
    end
  end
end
