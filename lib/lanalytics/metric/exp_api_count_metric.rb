module Lanalytics
  module Metric
    class ExpApiCountMetric < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_date, resource_id, page, per_page)
        result = datasource.exec do |client|
          query = {
            query: {
              bool: {
                must: [
                  {match: {verb: verbs.join(' OR ')}}
                ] + (all_filters(course_id, user_id))
              }
            }
          }
          query[:query][:bool][:filter] = {
            range: {
              timestamp: {
                gte: DateTime.parse(start_time).iso8601,
                lte: DateTime.parse(end_date).iso8601
              }
            }
          } if start_time.present? and end_date.present?

          client.count index: datasource.index, body: query
        end
        {count: result['count']}
      end

      def self.verbs
        []
      end
    end
  end
end
