module Lanalytics
  module Metric
    class ForumWriteActivity < ExpEventsElasticMetric

      description 'Total number of forum write events and its unique users.'

      optional_parameter :course_id, :user_id

      exec do |params|
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            track_total_hits: true,
            query: {
              bool: {
                must: [
                  {
                    bool: {
                      minimum_should_match: 1,
                      should: [
                        { match: { 'verb' => 'asked_question' } },
                        { match: { 'verb' => 'answered_question' } },
                        { match: { 'verb' => 'commented' } }
                      ]
                    }
                  }
                ] + all_filters(params[:user_id], params[:course_id], nil),
              }
            },
            aggs: {
              user: {
                cardinality: {
                  field: 'user.resource_uuid'
                }
              }
            }
          }
        end
        {
          total: result.dig('hits', 'total', 'value'),
          user: result.dig('aggregations', 'user', 'value')
        }
      end

    end
  end
end