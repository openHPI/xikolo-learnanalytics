# frozen_string_literal: true

module Reports::Openwho
  class CombinedCourseReport < Reports::Openwho::CourseReport
    def initialize(job)
      super

      @deanonymized =
        job.options['deanonymized']
      @include_enrollment_evaluation =
        job.options['include_enrollment_evaluation']
    end

    def generate!
      annotation =
        "#{classifier['cluster'].underscore}_#{classifier['title'].underscore}"

      @job.update(annotation: annotation)

      csv_file(
        "OpenWHO_CombinedCourseReport_#{@job.annotation}",
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
      @classifier ||= course_service.rel(:classifier).get(
        id: @job.task_scope,
      ).value!
    end
  end
end
