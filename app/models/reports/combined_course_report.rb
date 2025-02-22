# frozen_string_literal: true

module Reports
  class CombinedCourseReport < CourseReport
    queue_as :reports_long_running

    class << self
      def form_data
        {
          type: :combined_course_report,
          name: I18n.t(:'reports.combined_course_report.name'),
          description: I18n.t(:'reports.combined_course_report.desc'),
          scope: {
            type: 'select',
            name: :task_scope,
            label: I18n.t(:'reports.shared_options.select_classifier'),
            values: :classifiers,
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
              type: 'checkbox',
              name: :include_access_groups,
              label: I18n.t(:'reports.shared_options.access_groups'),
            },
            {
              type: 'checkbox',
              name: :include_profile,
              label: I18n.t(:'reports.shared_options.profile'),
            },
            {
              type: 'checkbox',
              name: :include_auth,
              label: I18n.t(:'reports.shared_options.auth'),
            },
            {
              type: 'checkbox',
              name: :include_analytics_metrics,
              label: I18n.t(:'reports.shared_options.analytics_metrics'),
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
      @extended = job.options['extended_flag']
      @include_sections = false
      @include_all_quizzes = false
    end

    def generate!
      @job.update(
        annotation:
          "#{classifier['cluster'].parameterize(separator: '_')}_" \
          "#{classifier['title'].parameterize(separator: '_')}",
      )

      csv_file("CombinedCourseReport_#{@job.annotation}", headers) do |&write|
        each_row(&write)
      end
    end

    private

    def courses
      @courses ||= course_service.rel(:courses).get({
        cat_id: @job.task_scope,
        groups: 'any',
      }).value!
    end

    def classifier
      @classifier ||= course_service.rel(:classifier)
        .get({id: @job.task_scope}).value!
    end
  end
end
