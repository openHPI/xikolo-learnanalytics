module Lanalytics
  module Metric
    class UserCourseCity < ExpApiMetric

      description 'Returns city with most activity.'

      optional_parameter :course_id, :user_id

      exec do |params|
        course_id = params[:course_id]
        user_id = params[:user_id]

        conditions = []

        if course_id.present?
          conditions << {
            match: {
              'in_context.course_id' => course_id
            }
          }
        end

        if user_id.present?
          conditions << {
            match: {
              'user.resource_uuid' => user_id
            }
          }
        end

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: conditions
              }
            },
            aggregations: {
              cities: {
                terms: {
                  field: 'in_context.user_location_city',
                  size: 100
                },
              }
            }
          }
        end

        if result['aggregations']['cities']['buckets'][0].present?
          result['aggregations']['cities']['buckets'][0]['key']
        else
          ''
        end
      end

    end
  end
end