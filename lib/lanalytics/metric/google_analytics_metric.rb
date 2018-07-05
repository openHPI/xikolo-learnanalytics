module Lanalytics
  module Metric
    class GoogleAnalyticsMetric < Base

      MAX_BATCH_SIZE = 5
      DEFAULT_PAGE_SIZE = 10000
      NOT_SET_VALUE = '(not set)'

      def self.datasource_keys
        %w(google_analytics)
      end

      def self.datasource
        datasources.first
      end

      def self.date_ranges(start_date = nil, end_date = nil)
        start_date = start_date.nil? ? datasource.adoption_date : start_date.to_date
        end_date = end_date.nil? ? Date.today : end_date.to_date
        [{
          start_date: start_date,
          end_date: end_date
        }]
      end

      def custom_dimension(name)
        index = datasource.custom_dimension_index name
        "ga:dimension#{index}".to_sym
      end

      def custom_metric(name)
        index = datasource.custom_metric_index name
        "ga:metric#{index}".to_sym
      end

      def self.course_filter(course_id)
        return {} if course_id.nil?
        {
          filters: [
            {
              dimension_name: custom_dimension(:course_id),
              operator: 'EXACT',
              expressions: [course_id]
            }
          ]
        }
      end

      def self.item_filter(item_id)
        return {} if item_id.nil?
        {
          filters: [
            {
              dimension_name: custom_dimension(:item_id),
              operator: 'EXACT',
              expressions: [item_id]
            }
          ]
        }
      end

      def self.request_report(request, limit: nil)
        request_reports([request], limit: limit)[0]
      end

      def self.request_reports(requests, limit: nil)
        if requests.size > MAX_BATCH_SIZE
          return requests.each_slice(MAX_BATCH_SIZE).map{ |chunk| request_reports chunk, limit: limit }.flatten
        end

        # Add default parameters to report requests
        requests = requests.map do |report_request|
          report_request.merge view_id: datasource.view_id.to_s,
                               page_size: limit || DEFAULT_PAGE_SIZE,
                               hide_value_ranges: true
        end

        # Request reports and handle pagination
        results = []
        incomplete_report_indices = (0...requests.size).to_a
        loop do
          response = datasource.exec do |client|
            client.batch_get_reports({report_requests: requests.values_at(*incomplete_report_indices)}, {})
          end

          # Parse requested reports and append to results
          incomplete_report_indices.map.with_index do |report_index, response_report_index|
            report = response.reports[response_report_index]
            results[report_index] ||= {
              rows: [],
              totals: metrics(report).zip(totals(report)).to_h
            }
            results[report_index][:rows] += parse_rows report
            requests[report_index][:page_token] = report.next_page_token
          end

          # Check, if limit or last page of any report has been reached
          incomplete_report_indices.delete_if.with_index do |report_index, response_report_index|
            response.reports[response_report_index].next_page_token.nil? || (!limit.nil? && results[report_index][:rows].size >= limit)
          end

          break if incomplete_report_indices.empty?
        end

        results
      end

      def self.dimensions(report)
        report.column_header.dimensions || []
      end

      def self.metrics(report)
        report.column_header.metric_header.metric_header_entries.map(&:name) || []
      end

      def self.totals(report)
        report.data.totals[0].values.map{ |value| value.to_f }
      end

      def self.parse_rows(report)
        return [] if report.data.rows.blank?

        report.data.rows.map do |row|
          {}.tap do |processed_row|
            dimensions(report).map.with_index do |name, index|
              processed_row[name] = sanitize(row.dimensions[index])
            end
            metrics(report).map.with_index do |name, index|
              processed_row[name] = sanitize(row.metrics[0].values[index]).to_f
            end
          end
        end
      end

      def self.sanitize(value)
        value unless value == NOT_SET_VALUE
      end
    end
  end
end