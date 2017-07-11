class CourseStatistic < ActiveRecord::Base
  has_paper_trail

  def calculate!
    course = Xikolo::Course::Course.find(course_id)
    Acfs.run
    course_stats = Xikolo::Course::Statistic.find course_id: course.id
    extended_course_stats = Xikolo::Course::Stat.find course_id: course.id, key: 'extended'
    pinboard_stats = Xikolo::Pinboard::Statistic.find course.id
    ticket_stats = Xikolo::Helpdesk::Statistic.find course_id: course.id
    enrollment_stats = Xikolo::Course::Stat.find course_id: course.id, key: 'enrollments_by_day'
    Acfs.run

    if extended_course_stats.certificates_count > 0 and (extended_course_stats.student_enrollments_at_middle_netto.to_f - extended_course_stats.no_shows) > 0
      completion_rate = extended_course_stats.certificates_count / (extended_course_stats.student_enrollments_at_middle_netto - extended_course_stats.no_shows).to_f
    else
      completion_rate = 0
    end

    days_since_course_start = course.start_date && (Date.today - course.start_date.to_date).to_i

    enrollments_per_day = []
    if course.status == 'active'
      enrollments_per_day = 9.downto(0).map do |num|
        day = num.days.ago.strftime('%Y-%m-%d')

        day_stats = enrollment_stats.student_enrollments_by_day.find do |(date, _enrollment_count)|
          date.start_with? day
        end

        day_stats ? day_stats[1] : 0
      end
    end

    update(
      course_name: course.title,
      course_code: course.course_code,
      course_id: course.id,
      course_status: course.status,
      total_enrollments: course_stats.enrollments,
      no_shows: extended_course_stats.no_shows,
      current_enrollments: course_stats.current_enrollments,
      enrollments_last_day: course_stats.last_day_enrollments,
      enrollments_at_course_start: extended_course_stats.student_enrollments_at_start,
      enrollments_at_course_middle_netto: extended_course_stats.student_enrollments_at_middle,
      enrollments_at_course_middle: extended_course_stats.student_enrollments_at_middle_netto,
      enrollments_at_course_end: extended_course_stats.student_enrollments_at_end,
      questions: pinboard_stats.questions,
      questions_last_day: pinboard_stats.questions_last_day,
      answers: pinboard_stats.answers,
      answers_last_day: pinboard_stats.answers_last_day,
      comments_on_answers: pinboard_stats.comments_on_answers,
      comments_on_answers_last_day: pinboard_stats.comments_on_answers_last_day,
      comments_on_questions: pinboard_stats.comments_on_questions,
      comments_on_questions_last_day: pinboard_stats.comments_on_questions_last_day,
      certificates: extended_course_stats.certificates_count,
      helpdesk_tickets: ticket_stats.ticket_count,
      helpdesk_tickets_last_day: ticket_stats.ticket_count_last_day,
      start_date: course.start_date,
      end_date: course.end_date,
      new_users: extended_course_stats.new_users,
      updated_at: DateTime.now,
      completion_rate: completion_rate,
      consumption_rate: 0, # Consumption rate needs to be calculated properly
      enrollments_per_day: enrollments_per_day,
      hidden: course.hidden,
      days_since_coursestart: days_since_course_start,
      questions_in_learning_rooms: pinboard_stats.questions_in_learning_rooms,
      questions_last_day_in_learning_rooms: pinboard_stats.questions_last_day_in_learning_rooms,
      answers_in_learning_rooms: pinboard_stats.answers_in_learning_rooms,
      answers_last_day_in_learning_rooms: pinboard_stats.answers_last_day_in_learning_rooms,
      comments_on_answers_in_learning_rooms: pinboard_stats.comments_on_answers_in_learning_rooms,
      comments_on_answers_last_day_in_learning_rooms: pinboard_stats.comments_on_answers_last_day_in_learning_rooms,
      comments_on_questions_in_learning_rooms: pinboard_stats.comments_on_questions_in_learning_rooms,
      comments_on_questions_last_day_in_learning_rooms: pinboard_stats.comments_on_questions_last_day_in_learning_rooms
    )
  end

  class << self
    def versions_for(course_id, start_date, end_date = nil)
      find_by(course_id: course_id)
        .versions
        .where("(object->>'course_id')= ?", course_id)
        .between(DateTime.parse(start_date), end_date || DateTime.now)
        .map do |version|
          version.object['version_created_at'] = version.created_at
          version.object
        end
    end
  end
end
