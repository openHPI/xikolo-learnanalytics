# frozen_string_literal: true

module Reports
  class OverallCourseSummaryReport < Base
    class << self
      def form_data
        {
          type: :overall_course_summary_report,
          name: I18n.t(:'reports.overall_course_summary_report.name'),
          description: I18n.t(:'reports.overall_course_summary_report.desc'),
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.shared_options.machine_headers'),
            },
            {
              type: 'checkbox',
              name: :include_statistics,
              label: I18n.t(:'reports.overall_course_summary_report.options.course_statistics'),
            },
            {
              type: 'date_field',
              name: :end_date,
              options: {min: '2013-01-01'},
              label: I18n.t(:'reports.overall_course_summary_report.options.end_date'),
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

      @include_statistics = job.options['include_statistics']
      @end_date = extract_end_date(job)
    end

    def generate!
      file_name = 'OverallCourseSummaryReport'
      if @include_statistics
        if @end_date
          file_name = "#{@end_date}_#{file_name}"
          @job.update(annotation: @end_date.to_s)
        else
          today = Time.zone.today
          file_name = "#{today}_#{file_name}"
          @job.update(annotation: today.to_s)
        end
      end

      csv_file(file_name, headers) do |&write|
        each_course(&write)
      end
    end

    private

    def headers
      headers = [
        'ID',
        'Code',
        'Title',
        'Status',
        'Hidden',
        'Start Date',
        'Display Start Date',
        'Course Middle Date',
        'Auto-Calculate Course Middle',
        'End Date',
        'Language',
        'Channel',
        'Records Released',
        'Forum is Locked',
        'Invitation only',
        'CoP Enabled',
        'CoP Threshold',
        'RoA Enabled',
        'RoA Threshold',
        'Proctored',
        'On-Demand',
        'Sections',
        'Published Sections',
        'Peer Assessment',
        'Collab Space',
        'Rating Stars',
        'Rating Votes',
      ]

      headers += clusters.map(&:humanize)

      if @include_statistics
        headers += [
          'Statistics Snapshot Date',
          'Enrollments (total)',
          'Enrollments (net)',
          'Enrollments (last 24h)',
          'Enrollments at Start',
          'Enrollments at Start (net)',
          'Enrollments at Middle',
          'Enrollments at Middle (net)',
          'Enrollments at End',
          'Enrollments at End (net)',
          'New Users',
          'Shows (total)',
          'Shows at Middle',
          'Shows at End',
          'No-Shows (total)',
          'No-Shows at Middle',
          'No-Shows at End',
          'Records of Achievement',
          'Confirmations of Participation',
          'Qualified Certificates',
          'Completion Rate',
          'Consumption Rate',
          'Posts',
          'Posts (last 24h)',
          'Topics',
          'Topics (last 24h)',
          'Collab Space Posts',
          'Collab Space Posts (last 24h)',
          'Collab Space Topics',
          'Collab Space Topics (last 24h)',
          'Helpdesk Tickets',
          'Issued Badges',
          'Downloaded Badges',
          'Shared Badges',
        ]
      end

      headers
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def each_course
      courses_counter = 0
      progress.update('courses', 0)

      courses_promise =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:courses).get(
            exclude_external: true,
            groups: 'any',
            per_page: 500,
          )
        end

      courses_promise.each_item do |course, page|
        sections = sections(course['id'])

        values = [
          course['id'],
          course['course_code'],
          escape_csv_string(course['title']),
          course['status'],
          course['hidden'],
          course['start_date'],
          course['display_start_date'],
          course['middle_of_course'],
          course['middle_of_course_is_auto'],
          course['end_date'],
          course['lang'],
          escape_csv_string(course['channel_name']),
          course['records_released'],
          course['forum_is_locked'],
          course['invite_only'],
          course['cop_enabled'],
          course['cop_threshold_percentage'],
          course['roa_enabled'],
          course['roa_threshold_percentage'],
          course['proctored'],
          course['on_demand'],
          sections.size,
          sections.count {|s| s['published'] },
          peer_assessment_type(course['id']),
          course['has_collab_space'],
          course['rating_stars'],
          course['rating_votes'],
        ]

        clusters.each do |c|
          values.append(
            escape_csv_string(course.dig('classifiers', c)&.join(',')),
          )
        end

        if @include_statistics
          begin
            stats =
              if @end_date&.past?
                CourseStatistic.last_version_at(course['id'], @end_date.to_s)
              else
                CourseStatistic.find_by!(course_id: course['id'])
              end
          rescue ActiveRecord::RecordNotFound # no statistic available yet
            stats = nil
          end

          values += [
            stats&.updated_at,
            stats&.total_enrollments,
            stats&.current_enrollments,
            stats&.enrollments_last_day,
            stats&.enrollments_at_course_start,
            stats&.enrollments_at_course_start_netto,
            stats&.enrollments_at_course_middle,
            stats&.enrollments_at_course_middle_netto,
            stats&.enrollments_at_course_end,
            stats&.enrollments_at_course_end_netto,
            stats&.new_users,
            stats&.shows,
            stats&.shows_at_middle,
            stats&.shows_at_end,
            stats&.no_shows,
            stats&.no_shows_at_middle,
            stats&.no_shows_at_end,
            stats&.roa_count,
            stats&.cop_count,
            stats&.qc_count,
            stats&.completion_rate,
            stats&.consumption_rate,
            stats&.posts,
            stats&.posts_last_day,
            stats&.threads,
            stats&.threads_last_day,
            stats&.posts_in_collab_spaces,
            stats&.posts_last_day_in_collab_spaces,
            stats&.threads_in_collab_spaces,
            stats&.threads_last_day_in_collab_spaces,
            stats&.helpdesk_tickets,
            stats&.badge_issues,
            stats&.badge_downloads,
            stats&.badge_shares,
          ]
        end

        yield values

        courses_counter += 1
        progress.update(
          'courses',
          courses_counter,
          max: page.response.headers['X_TOTAL_COUNT'].to_i,
        )
      end
    end
    # rubocop:enable all

    def clusters
      @clusters ||= Lanalytics.config.reports['classifiers'] || []
    end

    def extract_end_date(job)
      key = 'end_date'

      return if job.options[key].blank? # end_date is an optional parameter

      begin
        Date.parse(job.options[key], '%Y-%m-%d')
      rescue Date::Error
        raise InvalidReportArgumentError.new(key, job.options[key])
      end
    end

    def sections(course_id)
      sections = []

      sections_promise =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 20.seconds) do
          course_service.rel(:sections).get(course_id:)
        end

      sections_promise.each_item {|section| sections << section }

      sections
    end

    def peer_assessment_type(course_id)
      pa_type = ''

      items_promise =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:items).get(
            course_id:,
            content_type: 'peer_assessment',
          )
        end

      items_promise.each_item do |item|
        break if pa_type == 'team'

        pa = peerassessment_service
          .rel(:peer_assessment).get(id: item['content_id']).value!

        pa_type = pa['is_team_assessment'] ? 'team' : 'solo'
      end

      pa_type
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def peerassessment_service
      @peerassessment_service ||= Restify.new(:peerassessment).get.value!
    end
  end
end
