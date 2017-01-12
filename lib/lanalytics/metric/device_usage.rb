module Lanalytics
  module Metric
    class DeviceUsage < ExpApiMetric
      include Lanalytics::Helper::PercentageHelper

      def self.query(user_id, course_id, start_time, end_time, resource_id, page, per_page)
        query_must = []
        if user_id.present?
          query_must << [
            { match: { 'user.resource_uuid' => user_id } }
          ]
        end

        if course_id.present?
          query_must << {
            bool: {
              should: [
                { match: { 'in_context.course_id' => course_id } },
                { match: { 'resource.resource_uuid' => course_id } }
              ]
            }
          }
        end

        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: query_must
              }
            },
            aggregations: {
              platforms: {
                terms: {
                  field: 'in_context.platform'
                },
                aggregations: {
                  runtimes: {
                    terms: {
                      field: 'in_context.runtime'
                    }
                  }
                }
              },
              runtimes: {
                terms: {
                  field: 'in_context.runtime'
                }
              }
            }
          }
        end

        processed_result = {}

        # total platforms
        total_activity = 0
        result['aggregations']['platforms']['buckets'].each { |item| total_activity += item['doc_count'] }

        # process platforms
        platforms = []
        result['aggregations']['platforms']['buckets'].each do |platform|
          result_subitem = {}
          result_subitem[:platform] = platform['key']
          result_subitem[:total_activity] = platform['doc_count']
          result_subitem[:relative_activity] = platform['doc_count'].percent_of total_activity

          # process nested runtimes for platform
          runtimes = []
          platform['runtimes']['buckets'].each do |runtime|
            result_subsubitem = {}
            result_subsubitem[:runtime] = runtime['key']
            result_subsubitem[:total_activity] = runtime['doc_count']
            result_subsubitem[:relative_activity] = runtime['doc_count'].percent_of platform['doc_count']

            runtimes << result_subsubitem
          end

          # sort and add nested runtimes for platform
          runtimes.sort_by! { |i| i[:total_activity] }.reverse!
          result_subitem[:runtimes] = runtimes

          platforms << result_subitem
        end
        # sort and add platforms
        platforms.sort_by! { |i| i[:total_activity] }.reverse!
        processed_result[:platforms] = platforms

        # total runtimes
        total_activity = 0
        result['aggregations']['runtimes']['buckets'].each { |item| total_activity += item['doc_count'] }

        # process runtimes
        runtimes = []
        mobile = 0
        web = 0
        mobile_runtimes = ['android', 'ios']
        result['aggregations']['runtimes']['buckets'].each do |runtime|
          # count mobile and web usage
          if mobile_runtimes.include? runtime['key'].downcase
            mobile += runtime['doc_count']
          else
            web += runtime['doc_count']
          end

          result_subitem = {}
          result_subitem[:runtime] = runtime['key']
          result_subitem[:total_activity] = runtime['doc_count']
          result_subitem[:relative_activity] = runtime['doc_count'].percent_of total_activity

          runtimes << result_subitem
        end
        # sort and add runtimes
        runtimes.sort_by! { |i| i[:total_activity] }.reverse!
        processed_result[:runtimes] = runtimes

        # evaluate behavior
        state = 'unknown'
        usage = []
        # mobile and web is used
        if mobile > 0 and web > 0
          state = 'mixed'
          usage << {
            category: 'mobile',
            total_activity: mobile,
            relative_activity: mobile.percent_of(total_activity)
          }
          usage << {
            category: 'web',
            total_activity: web,
            relative_activity: web.percent_of(total_activity)
          }
        # only mobile used
        elsif mobile > 0
          state = 'mobile'
          usage << {
            category: 'mobile',
            total_activity: mobile,
            relative_activity: mobile.percent_of(total_activity)
          }
        # only web used
        elsif web > 0
          state = 'web'
          usage << {
            category: 'web',
            total_activity: web,
            relative_activity: web.percent_of(total_activity)
          }
        end

        # sort usage
        usage.sort_by! { |i| i[:total_activity] }.reverse!

        # add behavior
        behavior = {
          state: state,
          usage: usage
        }
        processed_result[:behavior] = behavior

        return processed_result
      end

    end
  end
end