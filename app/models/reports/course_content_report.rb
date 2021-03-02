module Reports
  class CourseContentReport < Base

    def initialize(job)
      super
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file "CourseContentReport_#{course['course_code']}", headers, &method(:each_item)
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
        'Course Code'
      ]
    end

    def each_item
      index = 0

      Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
        course_service.rel(:items).get(
          course_id: course['id'], per_page: 500
        )
      end.each_item do |item, page|
        section = sections.find { |section| section['id'] == item['section_id'] }

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
          course['course_code']
        ]

        yield values

        index += 1
        @job.progress_to(index, of: page.response.headers['X_TOTAL_COUNT'])
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
