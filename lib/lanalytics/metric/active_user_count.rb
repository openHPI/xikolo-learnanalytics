module Lanalytics
  module Metric
    class ActiveUserCount < ExpEventsElasticMetric

      description 'The number of distinct active users. The default time range is 30 minutes.'

      optional_parameter :start_date, :end_date, :course_id, :resource_id

      exec do |params|
        start_date = params[:start_date]
        end_date = params[:end_date]
        course_id = params[:course_id]
        resource_id = params[:resource_id]

        result = datasource.exec do |client|
          # default 30 min
          start_date = start_date.present? ? DateTime.parse(start_date) : (DateTime.now - 30.minutes)
          end_date = end_date.present? ? DateTime.parse(end_date) : (DateTime.now)

          body = {
            size: 0,
            query: {
              bool: {
                filter: {
                  range: {
                    timestamp: {
                      gte: start_date.iso8601,
                      lte: end_date.iso8601
                    }
                  }
                }
              }
            },
            aggs: {
              distinct_user_count: {
                cardinality: {
                  field: 'user.resource_uuid'
                }
              }
            }
          }

          if course_id.present?
            body[:query][:bool][:minimum_should_match] = 1
            body[:query][:bool][:should] = []
            body[:query][:bool][:should] << { match: { 'in_context.course_id' => course_id } }
            body[:query][:bool][:should] << { match: { 'resource.resource_uuid' => course_id } }
          end

          if resource_id.present?
            courses = Restify.new(:course).get.value!
              .rel(:courses).get(cat_id: resource_id).value!
            body[:query][:bool][:minimum_should_match] = 1
            body[:query][:bool][:should] = []
            courses.each do |course|
              body[:query][:bool][:should] << { match: { 'in_context.course_id' => course['id'] } }
              body[:query][:bool][:should] << { match: { 'resource.resource_uuid' => course['id'] } }
            end
          end

          client.search index: datasource.index, body: body
        end

        { active_users: result['aggregations']['distinct_user_count']['value'] }
      end

    end
  end
end
