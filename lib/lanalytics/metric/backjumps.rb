module Lanalytics
  module Metric
    class Backjumps < GoogleAnalyticsMetric
      include Lanalytics::Helper::PercentageHelper

      description 'Counts the number of visits for items of a course that are backjumps'

      required_parameter :course_id

      optional_parameter :start_date, :end_date, :item_id

      exec do |params|
        ordered_item_ids = get_ordered_item_ids params[:course_id]
        queried_item_ids = params[:item_id].present? ? [params[:item_id]] : ordered_item_ids
        next {items: []} if ordered_item_ids.empty?

        # Total visits per course item
        result = request_report pageviews_report_request(params, {
          filters: [
            {
              dimension_name: 'ga:dimension2',
              operator: 'IN_LIST',
              expressions: queried_item_ids
            }
          ]
        })
        total_visits = result[:rows].map {|row| [row['ga:dimension2'], row['ga:pageviews']]}.to_h

        # Backjump visits per course item
        result = request_reports(total_visits.keys.map do |item_id|
          succeeding_item_ids = ordered_item_ids.drop(ordered_item_ids.index(item_id) + 1)
          next if succeeding_item_ids.empty?

          pageviews_report_request(params, item_filter(item_id), {
            filters: [
              {
                dimension_name: 'ga:previousPagePath',
                operator: 'IN_LIST',
                expressions: succeeding_item_ids.map {|prev_item_id| "/courses/#{params[:course_id]}/item/#{prev_item_id}"}
              }
            ]
          })
        end.compact)
        total_backjumps = result.select{ |item_result| item_result[:rows].present? }
                                .map{ |item_result| [item_result[:rows][0]['ga:dimension2'], item_result[:rows][0]['ga:pageviews']] }
                                .to_h

        # Process results
        processed_result = {}
        processed_result[:items] = queried_item_ids.map do |item_id|
          item_backjumps = total_backjumps[item_id] || 0
          item_visits = total_visits[item_id] || 0
          {
            item_id: item_id,
            total_visits: item_visits,
            total_backjumps: item_backjumps,
            relative_backjumps: item_visits == 0 ? 0 : item_backjumps.percent_of(item_visits)
          }
        end.sort_by { |item| item[:relative_backjumps] }.reverse

        processed_result
      end

      def self.get_ordered_item_ids(course_id)
        Rails.cache.fetch("ordered_item_ids/#{course_id}", expires_in: 1.hour) do
          sections_index = get_sections(course_id).map { |section| [section['id'], section] }.to_h
          ordered_items = get_items(course_id).sort_by { |item| [sections_index[item['section_id']]['position'], item['position']] }
          ordered_items.map { |item| item['id'] }
        end
      end

      def self.get_sections(course_id)
        sections = []
        Xikolo.paginate(
          Xikolo.api(:course).value!.rel(:sections).get(
            course_id: course_id,
            include_alternatives: true
          )
        ) do |section|
          sections << section
        end

        sections
      end

      def self.get_items(course_id)
        items = []
        Xikolo.paginate(
          Xikolo.api(:course).value!.rel(:items).get(
            course_id: course_id
          )
        ) do |item|
          items << item
        end

        items
      end

      def self.pageviews_report_request(params, *dimension_filters)
        {
          date_ranges: date_ranges(params[:start_date], params[:end_date]),
          dimensions: [
            { name: 'ga:dimension2' },
          ],
          metrics: [
            { expression: 'ga:pageviews' }
          ],
          dimension_filter_clauses: [
            course_filter(params[:course_id]),
            *dimension_filters
          ]
        }
      end
    end
  end
end
