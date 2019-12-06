module Lanalytics
  module Metric
    class LastActivity < ExpEventsElasticMetric

      description 'Last activity of user.'

      required_parameter :user_id

      optional_parameter :course_id

      exec do |params|
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 1,
            query: {
              bool: {
                must: all_filters(params[:user_id], params[:course_id], nil),
              }
            },
            sort: {
              timestamp: {
                order: 'desc'
              }
            }
          }
        end
        result.dig('hits', 'hits', 0, '_source') || {}
      end

    end
  end
end
