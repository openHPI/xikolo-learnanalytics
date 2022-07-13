module Lanalytics
  module Metric
    class TopReferrers < LinkTrackingEventsElasticMetric
      description 'Top 25 referrer with count.'

      optional_parameter :course_id, :group_hosts

      exec do |params|
        result = datasource.exec do |client|
          body = {
            size: 0,
            aggregations: {
              referrer: {
                terms: {
                  field: 'referrer',
                  size: 25
                }
              }
            }
          }

          if params[:course_id].present?
            body[:query] = {
              bool: {
                must: [
                  {match: {'course_id' => params[:course_id]}}
                ]
              }
            }
          end

          client.search index: datasource.index, body: body
        end

        result_set = {}
        result['aggregations']['referrer']['buckets'].each do |item|
          referrer = item['key']
          if params[:group_hosts].presence
            referrer = referrer.split('/').first
          end
          result_set[referrer] = 0 if result_set[referrer].nil?
          result_set[referrer] += item['doc_count']
        end
        result_set
      end
    end
  end
end
