module Lanalytics
  module Metric
    class DownloadTotalCount < ExpApiMetric

      description 'Counts all downloads for all video items of a course.'

      required_parameter :course_id

      exec do |params|
        verbs = %w[
          hd_video
          sd_video
          hls_video
          slides
          audio
          transcript
        ]

        body = {
          size: 0,
          query: {
            bool: {
              must: all_filters(nil, params[:course_id], nil) + download_verbs_filter(verbs)
            }
          }
        }

        result = datasource.exec do |client|
          client.search index: datasource.index, body: body
        end

        { count: result.dig('hits', 'total').to_i }
      end

      def self.download_verbs_filter(verbs)
        filter = [{ bool: { should: [] } }]
        verbs.each do |verb|
          filter[0][:bool][:should] << { match: { verb: "downloaded_#{verb}" } }
        end
        filter
      end

    end
  end
end
