class CourseStatisticDecorator < ApplicationDecorator
  delegate_all

  def as_json (**opts)
    {
      id: model.id,
      course_code: model.course_code,
      course_name: model.course_name,
      course_id: model.course_id,
      course_status: model.course_status,
      total_enrollments: model.total_enrollments,
      no_shows: model.no_shows,
      current_enrollments: model.current_enrollments,
      enrollments_last_day: model.enrollments_last_day,
      enrollments_at_course_start: model.enrollments_at_course_start,
      enrollments_at_course_middle_netto: model.enrollments_at_course_middle_netto,
      enrollments_at_course_middle: model.enrollments_at_course_middle,
      enrollments_at_course_end: model.enrollments_at_course_end,
      threads: model.threads,
      threads_last_day: model.threads_last_day,
      posts: model.posts,
      posts_last_day: model.posts_last_day,
      threads_in_collab_spaces: model.threads_in_collab_spaces,
      threads_last_day_in_collab_spaces: model.threads_last_day_in_collab_spaces,
      posts_in_collab_spaces: model.posts_in_collab_spaces,
      posts_last_day_in_collab_spaces: model.posts_last_day_in_collab_spaces,
      certificates: model.certificates,
      helpdesk_tickets: model.helpdesk_tickets,
      helpdesk_tickets_last_day: helpdesk_tickets_last_day,
      start_date: model.start_date,
      end_date: model.end_date,
      new_users: model.new_users,
      created_at: model.created_at,
      updated_at: model.updated_at,
      completion_rate: model.completion_rate,
      consumption_rate: model.consumption_rate,
      enrollments_per_day: model.enrollments_per_day,
      hidden: model.hidden,
      days_since_coursestart: model.days_since_coursestart
    }.as_json(**opts)
  end
end
