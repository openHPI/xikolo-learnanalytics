module Lanalytics
  module Metric
    class ExpApiCountMetric
      def self.query(user_id, course_id, start_time, end_date)
        result = datasource.exec do |client|
          client.count index: datasource.index, body: {
            query: {
              filtered: {
                query: {
                  bool: {
                    must: [
                      {match_phrase: {'user.resource_uuid' => user_id}},
                      {match: {verb: verbs.join(' OR ')}}
                    ] + (all_filters(course_id))
                  }
                },
                filter: {
                  range: {
                    timestamp: {
                      gte: DateTime.parse(start_time).iso8601,
                      lte: DateTime.parse(end_date).iso8601
                    }
                  }
                }
              }}}
        end
        {count: result['count']}
      end

      def self.datasource
        Lanalytics::Processing::DatasourceManager.get_datasource(datasource_name)
      end

      def self.datasource_name
        'exp_api_elastic'
      end

      def self.verbs
        []
      end

      def self.all_filters(course_id)
        filters_ = if course_id.nil?
                     []
                   else
                     [{match_phrase: {'in_context.course_id' => course_id}}]
                   end
        filters_ + filters
      end

      def self.filters
        []
      end
    end
  end
end
