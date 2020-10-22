# frozen_string_literal: true

module Lanalytics
  module Metric
    class DeviceUsage < ExpEventsElasticMetric
      include Lanalytics::Helper::PercentageHelper
      extend Lanalytics::Helper::ClientUsageHelper

      description <<~DOC
        Returns the used platforms and runtimes, as well as an aggregated behavior state, which is either web, mobile or mixed.
      DOC

      optional_parameter :user_id, :course_id

      exec do |params|
        result = datasource.exec do |client|
          client.search index: datasource.index, body: {
            size: 0,
            query: {
              bool: {
                must: [
                  course_filter(params[:user_id]),
                  user_filter(params[:course_id]),
                ].compact,
              },
            },
            aggregations: {
              platforms: {
                terms: {
                  field: 'in_context.platform',
                  size: 50,
                },
                aggregations: {
                  runtimes: {
                    terms: {
                      field: 'in_context.runtime',
                      size: 50,
                    },
                  },
                },
              },
              runtimes: {
                terms: {
                  field: 'in_context.runtime',
                  size: 50,
                },
              },
            },
          }
        end

        processed_result = {}

        desktop_web = 0
        mobile_web = 0
        mobile_app = 0

        # total activity
        total_activity = 0
        result['aggregations']['platforms']['buckets'].each do |item|
          total_activity += item['doc_count']
        end

        # process platforms
        platforms = []
        result['aggregations']['platforms']['buckets'].each do |platform|
          # count web usage
          if mobile_platforms.include? platform['key'].downcase
            mobile_web += platform['doc_count']
          else
            desktop_web += platform['doc_count']
          end

          result_subitem = {}
          result_subitem[:platform] = platform['key']
          result_subitem[:total_activity] = platform['doc_count']
          result_subitem[:relative_activity] =
            platform['doc_count'].percent_of(total_activity)

          # process nested runtimes for platform
          runtimes = []
          platform['runtimes']['buckets'].each do |runtime|
            result_subsubitem = {}
            result_subsubitem[:runtime] = runtime['key']
            result_subsubitem[:total_activity] = runtime['doc_count']
            result_subsubitem[:relative_activity] =
              runtime['doc_count'].percent_of(platform['doc_count'])

            runtimes << result_subsubitem
          end

          # sort and add nested runtimes for platform
          runtimes.sort_by! {|i| i[:total_activity] }.reverse!
          result_subitem[:runtimes] = runtimes

          platforms << result_subitem
        end
        # sort and add platforms
        platforms.sort_by! {|i| i[:total_activity] }.reverse!
        processed_result[:platforms] = platforms

        # process runtimes
        runtimes = []
        result['aggregations']['runtimes']['buckets'].each do |runtime|
          # count app usage
          if mobile_app_runtimes.include? runtime['key'].downcase
            mobile_app += runtime['doc_count']
            mobile_web -= runtime['doc_count']
          end

          result_subitem = {}
          result_subitem[:runtime] = runtime['key']
          result_subitem[:total_activity] = runtime['doc_count']
          result_subitem[:relative_activity] =
            runtime['doc_count'].percent_of(total_activity)

          runtimes << result_subitem
        end
        # sort and add runtimes
        runtimes.sort_by! {|i| i[:total_activity] }.reverse!
        processed_result[:runtimes] = runtimes

        # evaluate behavior
        usage = [
          {
            category: 'desktop web',
            total_activity: desktop_web,
            relative_activity: desktop_web.percent_of(total_activity),
          },
          {
            category: 'mobile web',
            total_activity: mobile_web,
            relative_activity: mobile_web.percent_of(total_activity),
          },
          {
            category: 'mobile app',
            total_activity: mobile_app,
            relative_activity: mobile_app.percent_of(total_activity),
          },
        ]

        # sort usage
        usage.sort_by! {|i| i[:total_activity] }.reverse!

        # add behavior
        behavior = {usage: usage}
        processed_result[:behavior] = behavior

        processed_result
      end
    end
  end
end
