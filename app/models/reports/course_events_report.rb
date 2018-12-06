module Reports
  class CourseEventsReport < Base
    def initialize(job)
      super

      @deanonymized = job.options['deanonymized']
      @verb = job.options['verb']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file "CourseEventsReport_#{course['id']}", headers, &method(:each_event)
    end

    private

    def headers
      ['User ID', 'Verb', 'Resource ID', 'Timestamp', 'Context', 'Type', 'Item', 'Section']
    end

    # Handle each course event, prepare it for CSV output and yield it to the caller
    def each_event
      # We currently do not generate these reports for courses without start or end date
      return unless course['start_date'].present? and course['end_date'].present?

      each_page do |page|
        page[:data].each do |row|
          # Skip deprecated events
          next if %w(
            VISITED
            VIEWED_PAGE
          ).include? row[:verb]

          yield transform(row)
        end
      end
    end

    # Scroll through the course events, page by page, and yield each page to the caller
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
      row[:user_id] = @deanonymized ? row[:user_id] : Digest::SHA256.hexdigest(row[:user_id])

      row[:context] = @deanonymized ? row[:context].to_json : row[:context].except('user_ip', 'user_agent').to_json

      # We add three more columns with information related to course items
      item = items[row[:resource_id]] || items[JSON.parse(row[:context])['item_id']] || {}
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
        scroll_id: scroll_id
      )
    end

    def course
      @course ||= course_service.rel(:course).get(id: @job.task_scope).value!
    end

    def sections
      @sections ||= course_service.rel(:sections).get(
        course_id: course['id'],
        per_page: 200
      ).value!.map do |item|
        [item.id, item]
      end.to_h
    end

    def items
      @items ||= course_service.rel(:items).get(
        course_id: course['id'],
        per_page: 500
      ).value!.map do |item|
        [item.id, item]
      end.to_h
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
