module Lanalytics
  module Metric
    class ShareButtonClicks < ExpApiMetric

      description 'Top 25 share button click services with count.'

      optional_parameter :user_id, :course_id, :start_date, :end_date

      exec do |params|
        user_id = params[:user_id]
        course_id = params[:course_id]
        start_date = params[:start_date]
        end_date = params[:end_date]

        result = datasource.exec do |client|
          query_must = all_filters(user_id, course_id, nil)

          query_must << [
            { match: { 'verb' => 'share_button_click' } }
          ]

          query = {
            size: 0,
            query: {
              bool: {
                must: query_must
              }
            },
            aggregations: {
              services: {
                terms: {
                  field: 'in_context.service',
                  size: 25
                }
              }
            }
          }

          if start_date.present? and end_date.present?
            query[:query][:bool][:filter] = {
              range: {
                timestamp: {
                  gte: DateTime.parse(start_date).iso8601,
                  lte: DateTime.parse(end_date).iso8601
                }
              }
            }
          end

          client.search index: datasource.index, body: query
        end

        result['aggregations']['services']['buckets'].each_with_object({}) do |service, hash|
          hash[service['key']] = service['doc_count']
        end
      end

    end
  end
end
