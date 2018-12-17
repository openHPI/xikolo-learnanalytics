class CourseStatisticDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    {
      id: model.id,
      course_code: model.course_code,
      course_id: model.course_id,
      course_status: model.course_status,
      start_date: model.start_date,
      end_date: model.end_date,
      hidden: model.hidden,
      days_since_coursestart: model.days_since_coursestart,
      created_at: model.created_at,
      updated_at: model.updated_at,

      # enrollments
      total_enrollments: model.total_enrollments,
      current_enrollments: model.current_enrollments,
      enrollments_per_day: model.enrollments_per_day,
      new_users: model.new_users,

      enrollments_last_day: model.enrollments_last_day,
      enrollments_at_course_start: model.enrollments_at_course_start,
      enrollments_at_course_start_netto: model.enrollments_at_course_start_netto,
      enrollments_at_course_middle: model.enrollments_at_course_middle,
      enrollments_at_course_middle_netto: model.enrollments_at_course_middle_netto,
      enrollments_at_course_end: model.enrollments_at_course_end,
      enrollments_at_course_end_netto: model.enrollments_at_course_end_netto,

      shows: model.shows,
      shows_at_middle: model.shows_at_middle,
      shows_at_end: model.shows_at_end,
      no_shows: model.no_shows,
      no_shows_at_middle: model.no_shows_at_middle,
      no_shows_at_end: model.no_shows_at_end,

      # active users
      active_users_last_day: model.active_users_last_day,
      active_users_last_7days: model.active_users_last_7days,

      # success
      certificates: model.certificates,
      completion_rate: model.completion_rate,

      # pinboard
      threads: model.threads,
      threads_last_day: model.threads_last_day,
      posts: model.posts,
      posts_last_day: model.posts_last_day,
      threads_in_collab_spaces: model.threads_in_collab_spaces,
      threads_last_day_in_collab_spaces: model.threads_last_day_in_collab_spaces,
      posts_in_collab_spaces: model.posts_in_collab_spaces,
      posts_last_day_in_collab_spaces: model.posts_last_day_in_collab_spaces,

      # helpdesk
      helpdesk_tickets: model.helpdesk_tickets,
      helpdesk_tickets_last_day: helpdesk_tickets_last_day,

      # open badges
      badge_issues: model.badge_issues,
      badge_downloads: model.badge_downloads,
      badge_shares: model.badge_shares,
    }.as_json(opts)
  end
end
