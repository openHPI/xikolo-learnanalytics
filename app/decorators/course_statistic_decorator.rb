class CourseStatisticDecorator < ApplicationDecorator
  delegate_all

  def as_json (**opts)
    {
    id: model.id,
    course_code: model.course_code,
    course_name: model.course_name,
    course_id: model.course_id,
    total_enrollments: model.total_enrollments,
    no_shows: model.no_shows,
    current_enrollments: model.current_enrollments,
    enrollments_last_24h: model.enrollments_last_24h,
    enrollments_at_course: model.enrollments_at_course,
    enrollments_at_course_middle_incl_unenrollments: model.enrollments_at_course_middle_incl_unenrollments,
    enrollments_at_course_middle:model.enrollments_at_course_middle,
    enrollments_at_course_end: model.enrollments_at_course_end,
    total_questions: model.total_questions,
    questions_last_24h: model.questions_last_24h,
    total_answers: model.total_answers,
    answers_last_24h: model.answers_last_24h,
    total_comments_on_answers: model.total_comments_on_answers,
    comments_on_answers_last_24h: model.comments_on_answers_last_24h,
    total_comments_on_questions: model.total_comments_on_questions,
    comments_on_questions_last_24h: comments_on_questions_last_24h,
    certificates: model.certificates,
    helpdesk_tickets: model.helpdesk_tickets,
    helpdesk_tickets_last_24h: helpdesk_tickets_last_24h,
    success_rate: model.success_rate || 0,
    start_date: model.start_date,
    end_date: model.end_date,
    new_users: model.new_users,
    created_at: model.created_at,
    updated_at: model.updated_at,
    completion_rate: model.enrollments_at_course_middle <= 0 ? 0 :  (model.certificates.to_f  / model.enrollments_at_course_middle * 100).round(2)
    }.as_json(**opts)
  end
end
