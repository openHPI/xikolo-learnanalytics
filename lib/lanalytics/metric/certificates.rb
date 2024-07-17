# frozen_string_literal: true

module Lanalytics
  module Metric
    class Certificates < ExpEventsElasticMetric
      description 'Returns the number of gained certificates.'

      optional_parameter :course_id, :start_date, :end_date

      exec do |params|
        body = {
          size: 0,
          query: {
            bool: {
              must: [
                {match: {'verb' => 'completed_course'}},
              ].append(
                course_filter(params[:course_id]),
                date_filter(params[:start_date], params[:end_date]),
              ).compact,
            },
          },
          aggs: {},
        }

        types = %w[record_of_achievement confirmation_of_participation certificate]

        types.each do |type|
          body[:aggs][type] = {
            filter: {
              bool: {
                must: [
                  {match: {"in_context.received_#{type}" => 'true'}},
                ],
              },
            },
            aggs: {
              course: {
                terms: {
                  field: 'in_context.course_id',
                  size: 1_000_000,
                },
                aggs: {
                  user: {
                    cardinality: {
                      field: 'user.resource_uuid',
                      precision_threshold: 40_000,
                    },
                  },
                },
              },
              total: {
                sum_bucket: {
                  buckets_path: 'course>user',
                },
              },
            },
          }
        end

        result = datasource.exec do |client|
          client.search(index: datasource.index, body:)
        end

        certificates = {}

        types.each do |type|
          certificates[type] = result.dig('aggregations', type, 'total', 'value').to_i
        end

        certificates.tap {|it| it['qualified_certificate'] = it.delete('certificate') }
      end
    end
  end
end
