module Reports
  class CombinedCourseReport < CourseReport
    def initialize(job)
      super

      @deanonymized = job.options['deanonymized']
      @extended = job.options['extended_flag']
      @include_sections = false
      @include_all_quizzes = false
    end

    def generate!
      @job.update(
        annotation: "#{classifier['cluster'].underscore}_#{classifier['title'].underscore}"
      )

      csv_file "CombinedCourseReport_#{@job.annotation}", headers, &method(:each_row)
    end

    private

    def courses
      @courses ||= course_service.rel(:courses).get(
        cat_id: @job.task_scope,
        affiliated: true
      ).value!
    end

    def classifier
      @classifier ||= course_service.rel(:classifier).get(id: @job.task_scope).value!
    end
  end
end
