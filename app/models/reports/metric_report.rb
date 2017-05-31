module Reports
  class MetricReport < Base
    def generate!
      @job.update(annotation: @job.task_scope.underscore)

      csv_file "MetricReport_#{@job.task_scope}", headers, &method(:each_row)
    end

    private

    def headers
      ['Course Code', 'Enrollments', 'Metric']
    end

    def each_row
      each_course do |course, stats|
        next if course['start_date'].blank? and course['end_date'].blank?

        row = [
          course['course_code'],
          stats.student_enrollments_at_end,
          @job.task_scope
        ]

        # Get metrics for each day from course start to course end
        start_day = Date.parse(course['start_date'])
        end_day = Date.parse(course['start_date'])
        row += (start_day..end_day).map do |day|
          metric = "Lanalytics::Metric::#{@job.task_scope}".constantize
          metric.query(
            nil,
            course['id'],
            day.iso8601,
            (day+1.day).iso8601,
            nil,
            nil,
            nil
          )
        end

        yield row
      end
    end

    def each_course
      courses = course_service.rel(:courses).get(
        public: true, exclude_external: true, affiliated: true, per_page: 250
      ).value!

      i = 0
      courses.each do |course|
        course_stats = Xikolo::Course::Stat.find key: 'enrollments',
                                                 course_id: course['id'],
                                                 start_date: course['start_date'],
                                                 end_date: course['end_date']
        Acfs.run

        yield course, course_stats

        i += 1
        @job.progress_to(i, of: courses.count)
      end
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
