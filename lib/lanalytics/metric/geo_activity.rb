module Lanalytics
  module Metric
    class GeoActivity < ExpApiMetric

      description 'Counted geo locations, defaults to 1 minute.'

      optional_parameter :course_id, :start_date, :end_date

      exec do |params|
        course_id = params[:course_id]
        start_date = params[:start_date]
        end_date = params[:end_date]
        start_date = start_date.present? ? DateTime.parse(start_date) : (DateTime.now - 1.minute)
        end_date = end_date.present? ? DateTime.parse(end_date) : (DateTime.now)

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 10000,
            query: {
              bool: {
                must: [
                  { exists: { field: 'in_context.user_location_longitude' } }
                ] + (all_filters(nil, course_id, nil)),
                filter: {
                  range: {
                    timestamp: {
                      gte: start_date.iso8601,
                      lte: end_date.iso8601
                    }
                  }
                }
              }
            }
          }
        end

        processed_result = {}
        # process result
        result['hits']['hits'].each do |item|
          item = item['_source']['in_context']
          key = item['user_location_longitude'] + item['user_location_latitude']
          if processed_result[key]
            processed_result[key][:count] += 1
          else
            processed_result[key] = { count: 1, lon: item['user_location_longitude'], lat: item['user_location_latitude'] }
          end
        end
        # we dont need the keys in our return value
        processed_result.values
      end

    end
  end
end
