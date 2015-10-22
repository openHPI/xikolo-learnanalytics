module Lanalytics
  module Metric
    class GeoActivity < ExpApiMetric
      def self.query(user_id, course_id, start_time, end_time)
        #defaults
        start_time =  start_time.present? ?  DateTime.parse(start_time) : (DateTime.now - 1.minute)
        end_time =  end_time.present? ?  DateTime.parse(end_time) : (DateTime.now)
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 10000,
            query: {
              filtered: {
                query: {
                    bool: {
                        must: [
                            {match: {verb: verbs.join(' OR ')}}
                        ]
                    }
                },
                filter: {
                  and: [{
                    range: {
                      timestamp: {
                        gte: start_time.iso8601,
                        lte: end_time.iso8601
                      }
                    }
                  },
                  {exists:{ field: 'in_context.user_location_longitude' }}]

                }
              }
            }
          }
        end
        processed_result = {}
        #process result
        result['hits']['hits'].each do |item|
          item = item['_source']['in_context']
          key = item['user_location_longitude'] + item['user_location_latitude']
          if processed_result[key]
            processed_result[key][:count] =  processed_result[key][:count] + 1
          else
            processed_result[key] = {count:1, lon: item['user_location_longitude'] , lat: item['user_location_latitude'] }
          end
        end
        #we dont need the keys in our return value
        processed_result.values
      end


      def self.verbs
       %w(VIEWED_PAGE)
      end
    end
  end
end
