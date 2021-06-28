# frozen_string_literal: true

module Reports
  class CombinedCourseReport < CourseReport
    queue_as :reports_long_running

    class << self
      def structure
        {
          type: :combined_course_report,
          name: I18n.t(:'reports.combined_course_report'),
          description: I18n.t(:'reports.combined_course_report_explanation'),
          scope: {
            type: 'select',
            name: :task_scope,
            values: :classifiers,
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
              type: 'checkbox',
              name: :include_access_groups,
              label: I18n.t(:'reports.include_access_groups'),
            },
            {
              type: 'checkbox',
              name: :include_profile,
              label: I18n.t(:'reports.include_profile'),
            },
            {
              type: 'checkbox',
              name: :include_auth,
              label: I18n.t(:'reports.include_auth'),
            },
            {
              type: 'checkbox',
              name: :include_analytics_metrics,
              label: I18n.t(:'reports.include_analytics_metrics'),
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
