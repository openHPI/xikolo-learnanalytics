module Lanalytics
  module Metric
    class CourseActivityList < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)

        start_time = start_time.present? ? DateTime.parse(start_time) : (DateTime.now - 1.day)
        end_time = end_time.present? ? DateTime.parse(end_time) : (DateTime.now)

        expresult = datasource.exec do |client|
          client.search index: datasource.index, body: {
              size: 0,
              query: {
                  filtered: {
                      filter: {
                          range: {
                              timestamp: {
                                  gte: start_time.iso8601,
                                  lte: end_time.iso8601
                              }
                          }
                      }
                  }
              },
              aggs: {
                group_by_field: {
                    terms: {
                          field: 'in_context.course_id',
                          order: { _count: "desc" }
                    },
                    aggs: {
                      group_by_field: {
                        terms: {
                          field: "verb",
                          order: { _count: "desc" }
                        }
                      }
                    }
                 }
             }
        }


        end
        result = {}
        puts expresult
        expresult.with_indifferent_access[:aggregations][:group_by_field][:buckets].each do |bucket|
          buckets = bucket.with_indifferent_access[:group_by_field][:buckets]
          #add new verbs here if needed

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

      def self.get_agg_value buckets, verb
         b = buckets.find{ |hash| hash["key"] == verb }
         if b.present?
           b[:doc_count].to_i
         else
           0
         end
      end

      def self.verbs
        []
      end
    end
  end
end
