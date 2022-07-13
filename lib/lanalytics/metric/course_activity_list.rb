module Lanalytics
  module Metric
    class CourseActivityList < ExpEventsElasticMetric
      description 'Returns the top 10 active courses, defaults to last 24h.'

      optional_parameter :start_date, :end_date

      exec do |params|
        start_date = params[:start_date]
        end_date = params[:end_date]

        start_date = start_date.present? ? DateTime.parse(start_date) : (DateTime.now - 1.day)
        end_date = end_date.present? ? DateTime.parse(end_date) : (DateTime.now)

        exp_result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              range: {
                timestamp: {
                  gte: start_date.iso8601,
                  lte: end_date.iso8601
                }
              }
            },
            aggs: {
              group_by_field: {
                terms: {
                  field: 'in_context.course_id',
                  order: {_count: 'desc'}
                },
                aggs: {
                  group_by_field: {
                    terms: {
                      field: 'verb',
                      order: {_count: 'desc'}
                    }
                  }
                }
              }
            }
          }
        end
        result = {}
        exp_result.with_indifferent_access[:aggregations][:group_by_field][:buckets].each do |bucket|
          buckets = bucket.with_indifferent_access[:group_by_field][:buckets]
          # add new verbs here if needed

          result[bucket.with_indifferent_access[:key]] = {
            course_id: bucket.with_indifferent_access[:key],
            visited: get_agg_value(buckets, 'visited'),
            watched_question: get_agg_value(buckets, 'watched_question'),
            asked_question: get_agg_value(buckets, 'asked_question'),
            answered_question: get_agg_value(buckets, 'answered_question'),
            commented: get_agg_value(buckets, 'commented')
          }
        end
        result
      end

      def self.get_agg_value(buckets, verb)
        b = buckets.find {|hash| hash["key"] == verb }
        if b.present?
          b[:doc_count].to_i
        else
          0
        end
      end
    end
  end
end
