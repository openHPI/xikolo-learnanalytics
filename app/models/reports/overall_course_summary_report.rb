module Reports
  class OverallCourseSummaryReport < Base

    def initialize(job)
      super

      @include_statistics = job.options['include_statistics']
      @end_day = job.options['end_day'].to_i
      @end_month = job.options['end_month'].to_i
      @end_year = job.options['end_year'].to_i
    end

    def generate!
      csv_file 'OverallCourseSummaryReport', headers, &method(:each_course)
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
        'Affiliated only',
        'Invitation only',
        'CoP Enabled',
        'CoP Threshold',
        'RoA Enabled',
        'RoA Threshold',
        'Proctored',
        'On-Demand',
        'Peer Assessment',
        'Collab Space',
        'Teleboard',
        'Rating Stars',
        'Rating Votes',
      ]

      headers += Xikolo.config.classifiers.map(&:humanize)

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

    def each_course
      index = 0

      Xikolo.paginate(
        course_service.rel(:courses).get(
          exclude_external: true,
          affiliated: true,
          per_page: 500
        )
      ) do |course, page|
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
          course['affiliated'],
          course['invite_only'],
          course['cop_enabled'],
          course['cop_threshold_percentage'],
          course['roa_enabled'],
          course['roa_threshold_percentage'],
          course['proctored'],
          course['on_demand'],
          peer_assessment_type(course['id']),
          course['has_collab_space'],
          course['has_teleboard'],
          course['rating_stars'],
          course['rating_votes'],
        ]

        Xikolo.config.classifiers.each do |c|
          values.append escape_csv_string(course.dig('classifiers', c)&.join(','))
        end

        if @include_statistics
          begin
            if end_date
              stats = CourseStatistic.last_version_at(course['id'], end_date)
            else
              stats = CourseStatistic.last_version(course['id'])
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

        index += 1
        @job.progress_to(index, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def end_date
      if @end_year > 0 && @end_month > 0 && @end_day > 0
        "#{@end_year}-#{@end_month}-#{@end_day}"
      else
        nil
      end
    end

    def peer_assessment_type(course_id)
      pa_type = ''
      Xikolo.paginate(
        course_service.rel(:items).get(
          course_id: course_id,
          content_type: 'peer_assessment'
        )
      ) do |item|
        break if pa_type == 'team'
        pa = peerassessment_service.rel(:peer_assessment).get(id: item['content_id']).value!
        pa_type = pa['is_team_assessment'] ? 'team' : 'solo'
      end
      pa_type
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

    def peerassessment_service
      @peerassessment_service ||= Xikolo.api(:peerassessment).value!
    end

  end
end
