# frozen_string_literal: true

module Reports
  class CourseEventsReport < Base
    queue_as :reports_long_running

    DEPRECATED_EVENTS = %w[VISITED VIEWED_PAGE].freeze

    class << self
      def structure
        {
          type: :course_events_report,
          name: I18n.t(:'reports.course_events_report'),
          description: I18n.t(:'reports.course_events_report_explanation'),
          scope: {
            type: 'select',
            name: :task_scope,
            values: :courses,
            options: {
              include_blank: I18n.t(:'reports.select'),
              required: true,
            },
          },
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.machine_headers'),
            },
            {
              type: 'checkbox',
              name: :de_pseudonymized,
              label: I18n.t(:'reports.de_pseudonymized'),
            },
            {
              type: 'text_field',
              name: :verb,
              options: {
                placeholder: I18n.t(:'reports.verb'),
                input_size: 'medium',
              },
            },
            {
              type: 'text_field',
              name: :zip_password,
              options: {
                placeholder: I18n.t(:'reports.zip_password'),
                input_size: 'large',
              },
            },
          ],
        }
      end
    end

    def initialize(job)
      super

      @de_pseudonymized = job.options['de_pseudonymized']
      @verb = job.options['verb']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file(
        "CourseEventsReport_#{course['id']}", headers, &method(:each_event)
      )
    end

    private

    def headers
      [
        @de_pseudonymized ? 'User ID' : 'User Pseudo ID',
        'Verb',
        'Resource ID',
        'Timestamp',
        'Context',
        'Type',
        'Item',
        'Section',
      ]
    end

    # Handle each course event, prepare it for
    # CSV output and yield it to the caller
    def each_event
      # We currently do not generate these reports
      # for courses without start or end date
      return unless course['start_date'].present? && course['end_date'].present?

      each_page do |page|
        page[:data].each do |row|
          # Skip deprecated events
          next if DEPRECATED_EVENTS.include? row[:verb]

          yield transform(row)
        end
      end
    end

    # Scroll through the course events, page by page,
    # and yield each page to the caller
    def each_page
      page = 1
      scroll_id = nil

      loop do
        paged = query_events(page, scroll_id)
        yield paged

        # When we reach the last page, bail out!
        break unless paged[:next]

        @job.progress_to(page, of: paged[:total_pages])
        page += 1
        scroll_id = paged[:scroll_id]
      end
    end

    # Transform one event's data for output to the CSV file
    def transform(row)
      # De-anonymize the user ID, if required
      row[:user_id] = if @de_pseudonymized
                        row[:user_id]
                      else
                        Digest::SHA256.hexdigest(row[:user_id])
                      end

      row[:context] = if @de_pseudonymized
                        row[:context].to_json
                      else
                        row[:context].except('user_ip', 'user_agent').to_json
                      end

      # We add three more columns with information related to course items
      item = items[row[:resource_id]] ||
             items[JSON.parse(row[:context])['item_id']] ||
             {}

      row[:type] = item['content_type']
      row[:item] = item['title']

      row[:section] = sections.dig(item['section_id'], 'title')

      row.values
    end

    def query_events(page, scroll_id)
      Lanalytics::Metric::CourseEvents.query(
        course_id: course['id'],
        start_date: course['start_date'],
        end_date: course['end_date'],
        verb: @verb,
        page: page,
        scroll_id: scroll_id,
      )
    end

    def course
      @course ||= course_service.rel(:course).get(id: @job.task_scope).value!
    end

    def sections
      @sections ||= course_service.rel(:sections).get(
        course_id: course['id'],
        per_page: 200,
      ).value!.index_by do |item|
        item['id']
      end
    end

    def items
      @items ||= course_service.rel(:items).get(
        course_id: course['id'],
        per_page: 500,
      ).value!.index_by do |item|
        item['id']
      end
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end
  end
end
