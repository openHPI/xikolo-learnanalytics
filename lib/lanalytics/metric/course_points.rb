# frozen_string_literal: true

module Lanalytics
  module Metric
    class CoursePoints < ExpEventsElasticMetric
      description 'Achieved points of user in course.'

      required_parameter :user_id, :course_id, :start_date, :end_date

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        start_date = params[:start_date]
        end_date = params[:end_date]

        completed_statements = datasource.exec do |client|
          client.search index: datasource.index, body: {
            query: {
              filtered: {
                query: {
                  bool: {
                    must: [
                      {match: {'user.resource_uuid' => user_id}},
                      {match: {verb: 'COMPLETED_COURSE'}},
                    ] + all_filters(nil, course_id, nil),
                    filter: {
                      range: {
                        timestamp: {
                          gte: DateTime.parse(start_date).iso8601,
                          lte: DateTime.parse(end_date).iso8601,
                        },
                      },
                    },
                  },
                },
              },
            },
          }
        end['hits']['hits']

        next {points: nil} if completed_statements.empty?

        {points: completed_statements.first['_source']['in_context']['points_achieved']}
      end
    end
  end
end
