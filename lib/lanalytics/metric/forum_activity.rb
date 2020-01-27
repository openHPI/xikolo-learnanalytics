module Lanalytics
  module Metric
    class ForumActivity < ExpEventsElasticMetric

      description 'Total number of all forum events and its unique users.'

      optional_parameter :course_id, :user_id

      exec do |params|
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  {
                    bool: {
                      minimum_should_match: 1,
                      should: [
                        { match: { 'verb' => 'visited_pinboard' } },
                        { match: { 'verb' => 'visited_question' } },
                        { match: { 'verb' => 'toggled_subscription' } },
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