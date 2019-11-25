# frozen_string_literal: true

module Lanalytics
  module Metric
    class FirstAction < ExpApiMetric
      description 'First action of a user in a course.'

      required_parameter :course_id, :user_id

      exec do |params|
        course_service = Xikolo.api(:course).value!

        course = course_service.rel(:course).get(id: params[:course_id]).value!

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 1,
            query: {
              bool: {
                must: [
                  {range: {timestamp: {gte: course['start_date']}}},
                ] + all_filters(params[:user_id], params[:course_id], nil),
              },
            },
            sort: {
              timestamp: {
                order: 'asc',
              },
            },
          }
        end
        result.dig('hits', 'hits', 0, '_source') || {}
      end
    end
  end
end
