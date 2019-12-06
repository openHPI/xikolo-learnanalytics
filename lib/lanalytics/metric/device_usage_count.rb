module Lanalytics
  module Metric
    class DeviceUsageCount < ExpEventsElasticMetric
      extend Lanalytics::Helper::ClientUsageHelper

      description 'Counts the web, mobile and mixed device usage per user.'

      optional_parameter :course_id, :resource_id

      exec do |params|
        mobile_conditions = mobile_app_runtimes.map do |runtime|
          { match: { 'in_context.runtime' => runtime } }
        end

        # build conditions for query
        conditions = all_filters(nil, params[:course_id], params[:resource_id])

        conditions << { exists: { field: 'in_context.runtime' }}

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: conditions
              }
            },
            aggs: {
              user: {
                cardinality: {
                  field: 'user.resource_uuid'
                }
              },
              mobile: {
                filter: {
                  bool: {
                    should: mobile_conditions
                  }
                },
                aggs: {
                  count: {
                    cardinality: {
                      field: 'user.resource_uuid'
                    }
                  }
                }
              },
              web: {
                filter: {
                  bool: {
                    must_not: mobile_conditions
                  }
                },
                aggs: {
                  count: {
                    cardinality: {
                      field: 'user.resource_uuid'
                    }
                  }
                }
              }
            }
          }
        end

        #process results
        {
          user: result['aggregations']['user']['value'],
          web: result['aggregations']['web']['count']['value'],
          mobile: result['aggregations']['mobile']['count']['value'],
          mixed: result['aggregations']['mobile']['count']['value'] + result['aggregations']['web']['count']['value'] - result['aggregations']['user']['value']
        }
      end

    end
  end
end