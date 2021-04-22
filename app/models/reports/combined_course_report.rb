# frozen_string_literal: true

module Reports
  class CombinedCourseReport < CourseReport
    queue_as :reports_long_running

    def initialize(job)
      super

      @de_pseudonymized = job.options['de_pseudonymized']
      @extended = job.options['extended_flag']
      @include_sections = false
      @include_all_quizzes = false
    end

    def generate!
      @job.update(
        annotation:
          "#{classifier['cluster'].underscore}_" \
          "#{classifier['title'].underscore}",
      )

      csv_file(
        "CombinedCourseReport_#{@job.annotation}",
        headers,
        &method(:each_row)
      )
    end

    private

    def courses
      @courses ||= course_service.rel(:courses).get(
        cat_id: @job.task_scope,
        groups: 'any',
      ).value!
    end

    def classifier
      @classifier ||= course_service.rel(:classifier)
        .get(id: @job.task_scope).value!
    end
  end
end
