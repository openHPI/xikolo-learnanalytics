class CourseStatistic < ApplicationRecord
  has_paper_trail

  def calculate!
    course = course_service.rel(:course).get(id: course_id).value!

    Xikolo::RetryingPromise.new(
      Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) { course_service.rel(:course_statistic).get(course_id: course['id']) },
      Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) { course_service.rel(:stats).get(course_id: course['id'], key: 'extended') },
      Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) { course_service.rel(:stats).get(course_id: course['id'], key: 'enrollments_by_day') },
      Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) { pinboard_service.rel(:statistic).get(id: course['id']) },
      Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) { helpdesk_service.rel(:statistics).get(course_id: course['id']) },
      Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) { certificate_service.rel(:open_badge_statistics).get(course_id: course['id']) }
    ) do |course_stats, extended_course_stats, enrollment_stats, pinboard_stats, ticket_stats, badge_stats|
      days_since_course_start = course['start_date'] && (Date.today - course['start_date'].to_date).to_i

      enrollments_per_day = []
      if course['status'] == 'active'
        enrollments_per_day = 9.downto(0).map do |num|
          date = num.days.ago.strftime('%Y-%m-%d')

          day_stats = enrollment_stats['student_enrollments_by_day'].find do |date_key, _enrollment_count|
            date_key.start_with? date
          end

          day_stats ? day_stats[1] : 0
        end
      end

      certificates = Lanalytics::Metric::Certificates.query(course_id: course['id'])

      if certificates['record_of_achievement'] > 0 && extended_course_stats['shows_at_middle'].to_i > 0
        completion_rate = certificates['record_of_achievement'] / extended_course_stats['shows_at_middle'].to_f
      else
        completion_rate = 0
      end

      if certificates['confirmation_of_participation'] > 0 && extended_course_stats['shows'].to_i > 0
        consumption_rate = certificates['confirmation_of_participation'] / extended_course_stats['shows'].to_f
      else
        consumption_rate = 0
      end

      update(
        course_id: course['id'],
        course_code: course['course_code'],
        course_status: course['status'],
        start_date: course['start_date']&.to_datetime,
        end_date: course['end_date']&.to_datetime,
        hidden: course['hidden'],
        days_since_coursestart: days_since_course_start,
        updated_at: DateTime.now,

        # enrollments
        total_enrollments: course_stats['enrollments'],
        current_enrollments: course_stats['current_enrollments'],
        enrollments_per_day: enrollments_per_day,
        new_users: extended_course_stats['new_users'],

        enrollments_last_day: course_stats['last_day_enrollments'],
        enrollments_at_course_start: extended_course_stats['student_enrollments_at_start'],
        enrollments_at_course_start_netto: extended_course_stats['student_enrollments_at_start_netto'],
        enrollments_at_course_middle: extended_course_stats['student_enrollments_at_middle'],
        enrollments_at_course_middle_netto: extended_course_stats['student_enrollments_at_middle_netto'],
        enrollments_at_course_end: extended_course_stats['student_enrollments_at_end'],
        enrollments_at_course_end_netto: extended_course_stats['student_enrollments_at_end_netto'],

        shows: extended_course_stats['shows'],
        shows_at_middle: extended_course_stats['shows_at_middle'],
        shows_at_end: extended_course_stats['shows_at_end'],
        no_shows: extended_course_stats['no_shows'],
        no_shows_at_middle: extended_course_stats['no_shows_at_middle'],
        no_shows_at_end: extended_course_stats['no_shows_at_end'],

        # active users
        active_users_last_day: Lanalytics::Metric::ActiveUserCount.query(
          course_id: course['id'],
          start_date: (DateTime.now - 1.day).iso8601(3)
        )[:active_users].to_i,

        active_users_last_7days: Lanalytics::Metric::ActiveUserCount.query(
          course_id: course['id'],
          start_date: (DateTime.now - 7.days).iso8601(3)
        )[:active_users].to_i,

        # success
        roa_count: certificates['record_of_achievement'],
        cop_count: certificates['confirmation_of_participation'],
        qc_count: certificates['qualified_certificate'],
        completion_rate: completion_rate,
        consumption_rate: consumption_rate,

        # pinboard
        questions: pinboard_stats['threads'].to_i,
        questions_last_day: pinboard_stats['threads_last_day'].to_i,
        answers: 0,
        answers_last_day: 0,
        comments_on_answers: 0,
        comments_on_answers_last_day: 0,
        comments_on_questions: pinboard_stats['posts'].to_i - pinboard_stats['threads'].to_i,
        comments_on_questions_last_day: pinboard_stats['posts_last_day'].to_i - pinboard_stats['threads_last_day'].to_i,
        questions_in_learning_rooms: pinboard_stats['threads_in_collab_spaces'].to_i,
        questions_last_day_in_learning_rooms: pinboard_stats['threads_last_day_in_collab_spaces'].to_i,
        answers_in_learning_rooms: 0,
        answers_last_day_in_learning_rooms: 0,
        comments_on_answers_in_learning_rooms: 0,
        comments_on_answers_last_day_in_learning_rooms: 0,
        comments_on_questions_in_learning_rooms: pinboard_stats['posts_in_collab_spaces'].to_i - pinboard_stats['threads_in_collab_spaces'].to_i,
        comments_on_questions_last_day_in_learning_rooms: pinboard_stats['posts_last_day_in_collab_spaces'].to_i - pinboard_stats['threads_last_day_in_collab_spaces'].to_i,

        # helpdesk
        helpdesk_tickets: ticket_stats['ticket_count'],
        helpdesk_tickets_last_day: ticket_stats['ticket_count_last_day'],

        # open badges
        badge_issues: badge_stats['issued'].to_i,
        badge_downloads: Lanalytics::Metric::BadgeDownloadCount.query(course_id: course['id'])[:count].to_i,
        badge_shares: Lanalytics::Metric::BadgeShareCount.query(course_id: course['id'])[:count].to_i,
      )
    end.value!
  end

  def threads
    questions.to_i
  end

  def threads_last_day
    questions_last_day.to_i
  end

  def posts
    questions.to_i + answers.to_i + comments_on_questions.to_i + comments_on_answers.to_i
  end

  def posts_last_day
    questions_last_day.to_i + answers_last_day.to_i + comments_on_questions_last_day.to_i + comments_on_answers_last_day.to_i
  end

  def threads_in_collab_spaces
    questions_in_learning_rooms.to_i
  end

  def threads_last_day_in_collab_spaces
    questions_last_day_in_learning_rooms.to_i
  end

  def posts_in_collab_spaces
    questions_in_learning_rooms.to_i + answers_in_learning_rooms.to_i + comments_on_questions_in_learning_rooms.to_i + comments_on_answers_in_learning_rooms.to_i
  end

  def posts_last_day_in_collab_spaces
    questions_last_day_in_learning_rooms.to_i + answers_last_day_in_learning_rooms.to_i + comments_on_questions_last_day_in_learning_rooms.to_i + comments_on_answers_last_day_in_learning_rooms.to_i
  end

  private

  def course_service
    @course_service ||= Restify.new(:course).get.value!
  end

  def pinboard_service
    @pinboard_service ||= Restify.new(:pinboard).get.value!
  end

  def helpdesk_service
    @helpdesk_service ||= Restify.new(:helpdesk).get.value!
  end

  def certificate_service
    @certificate_service ||= Restify.new(:certificate).get.value!
  end

  class << self
    def versions_for(course_id, start_date, end_date = nil)
      find_by!(course_id: course_id)
        .versions
        .where.not(object: nil)
        .between(DateTime.parse(start_date), end_date || DateTime.now)
        .map(&:reify)
    end

    def last_version_at(course_id, date)
      find_by!(course_id: course_id)
        .versions
        .where.not(object: nil)
        .preceding(DateTime.parse(date).end_of_day + 1.day, true)
        .last
        &.reify
    end
  end
end
