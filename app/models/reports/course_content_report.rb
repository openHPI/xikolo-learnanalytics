# frozen_string_literal: true

module Reports
  class CourseContentReport < Base
    class << self
      def form_data
        {
          type: :course_content_report,
          name: I18n.t(:'reports.course_content_report.name'),
          description: I18n.t(:'reports.course_content_report.desc'),
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

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file("CourseContentReport_#{course['course_code']}", headers) do |&write|
        each_item(&write)
      end
    end

    private

    def headers
      [
        'Item ID',
        'Item Title',
        'Item Position',
        'Content Type',
        'Content ID',
        'Exercise Type',
        'Icon Type',
        'Section ID',
        'Section Name',
        'Section Position',
        'Course Code',
      ]
    end

    def each_item
      items_counter = 0
      progress.update(course['id'], 0)

      items_promise = Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
        course_service.rel(:items).get(
          course_id: course['id'], per_page: 500,
        )
      end

      items_promise.each_item do |item, page|
        section = sections.find {|s| s['id'] == item['section_id'] }

        values = [
          item['id'],
          item['title'],
          item['position'],
          item['content_type'],
          item['content_id'],
          item['exercise_type'],
          item['item_type'],
          section&.dig('id') || '',
          section&.dig('title') || '',
          section&.dig('position') || '',
          course['course_code'],
        ]

        yield values

        items_counter += 1
        progress.update(
          course['id'],
          items_counter,
          max: page.response.headers['X_TOTAL_COUNT'].to_i,
        )
      end
    end

    def course
      @course ||= course_service.rel(:course).get(id: @job.task_scope).value!
    end

    def sections
      @sections ||= course_service.rel(:sections).get(course_id: course['id'], per_page: 50).value!
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end
  end
end
