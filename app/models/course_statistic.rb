class CourseStatistic < ActiveRecord::Base
  has_paper_trail

  class << self
    def versions_for(course_id, start_date, end_date)
      find_by(course_id: course_id)
        .versions
        .where("(object->>'course_id')= ?", course_id)
        .between(DateTime.parse(start_date), end_date || DateTime.now)
        .map do |version|
          version.object['version_created_at'] = version.created_at
          version.object
        end
    end

    def retrieve(course_id)
      course_statistic = CourseStatistic.find_or_create_by(course_id: course_id)
      calculate_statistic(course_id, course_statistic.id)

      CourseStatistic.find course_statistic.id
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
        course_stat: course_stat,
        extended_course_stat: extended_course_stat,
        helpdesk_stat: ticket_course_stat
      }
      if course_info[:extended_course_stat].certificates_count > 0 and (course_info[:extended_course_stat].student_enrollments_at_middle_netto.to_f - course_info[:extended_course_stat].no_shows) > 0
        completion_rate = course_info[:extended_course_stat].certificates_count / (course_info[:extended_course_stat].student_enrollments_at_middle_netto - course_info[:extended_course_stat].no_shows).to_f
      else
        completion_rate = 0
      end
      # consumption rate needs  to be calculated properly
      consumption_rate = 0

      if course_info[:course].start_date and course_info[:course].start_date.present?
        course_start = course_info[:course].start_date
        days_since_coursestart = (Date.today - course_start.to_date).to_i
      else
        days_since_coursestart = nil
      end

      # for enrollments per day:
      if course.status.present? and course.status == 'active'
        last_days = 9.downto(0).map do |num|
          num.days.ago.strftime("%Y-%m-%d")
        end
        cresults = Array.new(10).fill(0)
        last_days.each_with_index do |day, i|
          enrollments_per_day.student_enrollments_by_day.each do |item|
            #[["2016-03-23 00:00:00 UTC", 6]]
            cresults[i] = item[1] if item[0].start_with?(day)
          end
        end
      end
      CourseStatistic.update(course_statistic_id,
                             course_name: course_info[:course].title,
                             course_code: course_info[:course].course_code,
                             course_id: course_id,
                             course_status: course.status,
                             total_enrollments: course_info[:course_stat].enrollments,
                             no_shows: course_info[:extended_course_stat].no_shows,
                             current_enrollments: course_info[:course_stat].current_enrollments,
                             enrollments_last_day: course_info[:course_stat].last_day_enrollments,
                             enrollments_at_course_start: course_info[:extended_course_stat].student_enrollments_at_start,
                             enrollments_at_course_middle_netto: course_info[:extended_course_stat].student_enrollments_at_middle,
                             enrollments_at_course_middle: course_info[:extended_course_stat].student_enrollments_at_middle_netto,
                             enrollments_at_course_end: course_info[:extended_course_stat].student_enrollments_at_end,
                             questions: course_info[:pinboard_course_stat].questions,
                             questions_last_day: course_info[:pinboard_course_stat].questions_last_day,
                             answers: course_info[:pinboard_course_stat].answers,
                             answers_last_day: course_info[:pinboard_course_stat].answers_last_day,
                             comments_on_answers: course_info[:pinboard_course_stat].comments_on_answers,
                             comments_on_answers_last_day: course_info[:pinboard_course_stat].comments_on_answers_last_day,
                             comments_on_questions: course_info[:pinboard_course_stat].comments_on_questions,
                             comments_on_questions_last_day: course_info[:pinboard_course_stat].comments_on_questions_last_day,
                             certificates: course_info[:extended_course_stat].certificates_count,
                             helpdesk_tickets: course_info[:helpdesk_stat].ticket_count,
                             helpdesk_tickets_last_day: course_info[:helpdesk_stat].ticket_count_last_day,
                             start_date: course_info[:course].start_date,
                             end_date: course_info[:course].end_date,
                             new_users: course_info[:extended_course_stat].new_users,
                             updated_at: DateTime.now,
                             completion_rate: completion_rate,
                             consumption_rate: consumption_rate,
                             enrollments_per_day: cresults || [],
                             hidden: course_info[:course].hidden,
                             days_since_coursestart: days_since_coursestart,
                             questions_in_learning_rooms: course_info[:pinboard_course_stat].questions_in_learning_rooms,
                             questions_last_day_in_learning_rooms: course_info[:pinboard_course_stat].questions_last_day_in_learning_rooms,
                             answers_in_learning_rooms: course_info[:pinboard_course_stat].answers_in_learning_rooms,
                             answers_last_day_in_learning_rooms: course_info[:pinboard_course_stat].answers_last_day_in_learning_rooms,
                             comments_on_answers_in_learning_rooms: course_info[:pinboard_course_stat].comments_on_answers_in_learning_rooms,
                             comments_on_answers_last_day_in_learning_rooms: course_info[:pinboard_course_stat].comments_on_answers_last_day_in_learning_rooms,
                             comments_on_questions_in_learning_rooms: course_info[:pinboard_course_stat].comments_on_questions_in_learning_rooms,
                             comments_on_questions_last_day_in_learning_rooms: course_info[:pinboard_course_stat].comments_on_questions_last_day_in_learning_rooms
      )
    end
  end
end
