# frozen_string_literal: true

module Lanalytics
  module Metric
    class ClientCombinationUsage < ExpEventsElasticMetric
      include Lanalytics::Helper::PercentageHelper
      extend Lanalytics::Helper::ClientUsageHelper

      description \
        'Returns the number of users for any combination of client types'

      optional_parameter :course_id, :start_date, :end_date

      # rubocop:disable Metrics/BlockLength
      exec do |params|
        # Build filters for different client types
        mobile_web_platforms_conditions = mobile_platforms.map do |platform|
          {match: {'in_context.platform' => platform}}
        end
        mobile_app_runtimes_conditions = mobile_app_runtimes.map do |runtime|
          {match: {'in_context.runtime' => runtime}}
        end

        filters = {
          desktop_web: {
            bool: {
              must_not: mobile_web_platforms_conditions,
            },
          },
          mobile_web: {
            bool: {
              should: mobile_web_platforms_conditions,
              must_not: mobile_app_runtimes_conditions,
            },
          },
          mobile_app: {
            bool: {
              should: mobile_app_runtimes_conditions,
            },
          },
        }
        client_types = filters.keys

        # Build aggregation for each combination of client types
        aggregations = subsets(client_types).map do |subset|
          key = subset_key(subset)
          aggregation = {
            filter: {
              bool: {
                should: subset.map {|client_type| filters[client_type] },
              },
            },
            aggregations: {
              ucount: {
                cardinality: {
                  field: 'user.resource_uuid',
                },
              },
            },
          }
          [key, aggregation]
        end.to_h

        query = {
          size: 0,
          query: {
            bool: {
              must: [
                {exists: {field: 'in_context.platform'}},
                {exists: {field: 'in_context.runtime'}},
                {wildcard: {verb: 'visited_*'}},
              ].append(
                course_filter(params[:course_id]),
                date_filter(params[:start_date], params[:end_date]),
              ).compact,
            },
          },
          aggregations: aggregations,
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: query
        end

        # Compute intersections
        intersections = {}
        subsets(client_types).each do |subset|
          intersections[subset] =
            intersection_users(result, intersections, subset)
        end

        # Preprocess result
        total_users = union_users result, client_types
        intersections.map do |subset, users|
          {
            client_types: subset,
            total_users: users,
            relative_users: users.percent_of(total_users),
          }
        end
      end
      # rubocop:enable all

      def self.subsets(arr)
        (1..arr.size).flat_map {|size| arr.combination(size).to_a }
      end

      def self.subset_key(subset)
        subset.sort.join('_')
      end

      # rubocop:disable Metrics/AbcSize
      def self.intersection_users(result, intersections, client_types)
        # Inclusion-exclusion principle
        sign = (-1)**(client_types.size + 1)
        (union_users(result, client_types) + (1...client_types.size).map do |n|
          subset_sign = (-1)**n
          client_types.combination(n).map do |subset|
            intersections[subset]
          end.sum * subset_sign
        end.sum) * sign
      end
      # rubocop:enable all

      def self.union_users(result, client_types)
        key = subset_key(client_types)
        result['aggregations'][key]['ucount']['value']
      end
    end
  end
end
