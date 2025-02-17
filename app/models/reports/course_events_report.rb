# frozen_string_literal: true

module Reports
  class CourseEventsReport < Base
    queue_as :reports_long_running

    DEPRECATED_EVENTS = %w[VISITED VIEWED_PAGE].freeze

    class << self
      def form_data
        {
          type: :course_events_report,
          name: I18n.t(:'reports.course_events_report.name'),
          description: I18n.t(:'reports.course_events_report.desc'),
          scope: {
            type: 'select',
            name: :task_scope,
            label: I18n.t(:'reports.shared_options.select_course'),
            values: :courses,
            options: {
              prompt: I18n.t(:'reports.shared_options.select_blank'),
              disabled: '', # disable prompt option (rails 6)
              required: true,
            },
          },
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.shared_options.machine_headers'),
            },
            {
              type: 'checkbox',
              name: :de_pseudonymized,
              label: I18n.t(:'reports.shared_options.de_pseudonymized'),
            },
            {
              type: 'text_field',
              name: :verb,
              label: I18n.t(:'reports.course_events_report.options.verb'),
              options: {
                placeholder: I18n.t(:'reports.course_events_report.options.verb_placeholder'),
                input_size: 'large',
              },
            },
            {
              type: 'text_field',
              name: :zip_password,
              label: I18n.t(:'reports.shared_options.zip_password'),
              options: {
                placeholder: I18n.t(:'reports.shared_options.zip_password_placeholder'),
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

      csv_file("CourseEventsReport_#{course['course_code']}", headers) do |&write|
        each_event(&write)
      end
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
      page_number = 1
      scroll_id = nil
      progress.update(course['id'], 0)

      loop do
        page = query_events(page_number, scroll_id)

        yield page

        progress.update(
          course['id'],
          page_number,
          max: page[:total_pages].to_i,
        )

        # When we reach the last page, bail out!
        break unless page[:next]

        page_number += 1
        scroll_id = page[:scroll_id]
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
        page:,
        scroll_id:,
      )
    end

    def course
      @course ||= course_service.rel(:course).get({id: @job.task_scope}).value!
    end

    def sections
      @sections ||= course_service.rel(:sections).get({
        course_id: course['id'],
        per_page: 200,
      }).value!.index_by do |item|
        item['id']
      end
    end

    def items
      @items ||= course_service.rel(:items).get({
        course_id: course['id'],
        per_page: 500,
      }).value!.index_by do |item|
        item['id']
      end
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end
  end
end
