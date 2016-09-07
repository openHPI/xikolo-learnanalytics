class CourseStatisticsController < ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder
  respond_to :json

  def index
    course_statistics = CourseStatistic.all
    if params['offset'].nil?
      @offset = 0
    elsif
    @offset = params['offset']
    end
    respond_with course_statistics.offset(@offset)
  end

  def show
    # incoming id is course_id!
    course_id = params[:id]
    course_statistic = CourseStatistic.find_or_create_by(course_id: course_id)
    calculate_statistic(course_id, course_statistic.id)
    respond_with CourseStatistic.find course_statistic.id
  end

  def calculate_statistic(course_id, course_statistic_id)
    course = Xikolo::Course::Course.find(course_id)
    Acfs.run
    course_stat = Xikolo::Course::Statistic.find course_id: course.id
    extended_course_stat = Xikolo::Course::Stat.find course_id: course.id, key: 'extended'
    pinboard_course_stat = Xikolo::Pinboard::Statistic.find course.id
    ticket_course_stat = Xikolo::Helpdesk::Statistic.find course_id: course.id
    enrollments_per_day = Xikolo::Course::Stat.find course_id: course.id, key: 'enrollments_by_day'
    Acfs.run

    course_info = {
        course: course,
        pinboard_course_stat: pinboard_course_stat,
        enrollments_per_day: enrollments_per_day,
        course_stat: course_stat,
        extended_course_stat: extended_course_stat,
        helpdesk_stat: ticket_course_stat
    }
    if course_info[:extended_course_stat].certificates_count > 0 and (course_info[:extended_course_stat].student_enrollments_at_middle_netto.to_f - course_info[:extended_course_stat].no_shows) > 0
      completion_rate = course_info[:extended_course_stat].certificates_count / (course_info[:extended_course_stat].student_enrollments_at_middle_netto - course_info[:extended_course_stat].no_shows).to_f
    else
      completion_rate = 0
    end
    CourseStatistic.update(course_statistic_id,
                           course_name: course_info[:course].title,
                           course_code: course_info[:course].course_code,
                           course_id: course_id,
                           course_status: course.status,
                           total_enrollments: course_info[:course_stat].enrollments,
                           no_shows: course_info[:extended_course_stat].no_shows,
                           current_enrollments: course_info[:course_stat].current_enrollments,
                           enrollments_last_24h: course_info[:course_stat].last_day_enrollments,
                           enrollments_at_course: course_info[:extended_course_stat].student_enrollments_at_start,
                           enrollments_at_course_middle_incl_unenrollments:course_info[:extended_course_stat].student_enrollments_at_middle,
                           enrollments_at_course_middle: course_info[:extended_course_stat].student_enrollments_at_middle_netto,
                           enrollments_at_course_end: course_info[:extended_course_stat].student_enrollments_at_end,
                           total_questions: course_info[:pinboard_course_stat].questions,
                           questions_last_24h: course_info[:pinboard_course_stat].questions_last_day,
                           total_answers: course_info[:pinboard_course_stat].answers,
                           answers_last_24h: course_info[:pinboard_course_stat].answers_last_day,
                           total_comments_on_answers: course_info[:pinboard_course_stat].comments_on_answers,
                           comments_on_answers_last_24h: course_info[:pinboard_course_stat].comments_on_answers_last_day,
                           total_comments_on_questions: course_info[:pinboard_course_stat].comments_on_questions,
                           comments_on_questions_last_24h: course_info[:pinboard_course_stat].comments_on_questions_last_day,
                           certificates: course_info[:extended_course_stat].certificates_count,
                           helpdesk_tickets: course_info[:helpdesk_stat].ticket_count,
                           helpdesk_tickets_last_24h: course_info[:helpdesk_stat].ticket_count_last_day,
                           start_date: course_info[:course].start_date,
                           end_date: course_info[:course].end_date,
                           new_users: course_info[:extended_course_stat].new_users,
                           updated_at: DateTime.now,
                           completion_rate: completion_rate,
                           consumption_rate: 0
    )
  end
end
