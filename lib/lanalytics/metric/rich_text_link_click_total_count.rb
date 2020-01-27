# frozen_string_literal: true

module Lanalytics
  module Metric
    class RichTextLinkClickTotalCount < LinkTrackingEventsElasticMetric

      description 'Counts all link clicks for all rich text items of a course.'

      required_parameter :course_id

      exec do |params|
        body = {
          size: 0,
          track_total_hits: true,
          query: {
            bool: {
              must: [
                {match: {tracking_type: 'rich_text_item_link'}},
                {match: {course_id: params[:course_id]}},
              ],
            },
          },
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: body
        end

        {count: result.dig('hits', 'total', 'value').to_i}
      end

    end
  end
end
