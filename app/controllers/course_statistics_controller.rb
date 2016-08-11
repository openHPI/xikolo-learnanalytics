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

  def create
    puts "TADDDA"
    course_infos.each do |course_info|

    end
  end
  def show
    @all_course_infos = []
    courses = []

    courses << Xikolo::Course::Course.find(params[:course_id])
    Acfs.run
    courses.each do |course|
      course_stat =  Xikolo::Course::Statistic.find course_id: course.id
      extended_course_stat =  Xikolo::Course::Stat.find course_id: course.id, key: 'extended'
      pinboard_course_stat =  Xikolo::Pinboard::Statistic.find course.id
      ticket_course_stat =  Xikolo::Helpdesk::Statistic.find course_id: course.id
      enrollments_per_day = Xikolo::Course::Stat.find course_id: course.id, key: 'enrollments_by_day'
      Acfs.run

      course_object = {
          course: course,
          pinboard_course_stat: pinboard_course_stat,
          enrollments_per_day: enrollments_per_day,
          course_stat: course_stat,
          extended_course_stat: extended_course_stat,
          helpdesk_stat: ticket_course_stat
      }


      @all_course_infos << course_object
    end
    @all_course_infos.each do |course_info|
      x = CourseStatistic.new(course_name: course_info[:course].title,
                          course_code: course_info[:course].course_code,
                          total_enrollments: course_info[:course_stat].enrollments,
                          no_shows: course_info[:extended_course_stat].no_shows,
                          current_enrollments: course_info[:course_stat].current_enrollments,
                          enrollemnts_last_24h: course_info[:course_stat].last_day_enrollments,
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
                          success_rate: (course_info[:extended_course_stat].certificates_count.to_i > 0) ? "=(S"+(i+2).to_s+"/I"+(i+2).to_s + ") * 100" : '',
                          start_date: course_info[:course].start_date,
                          end_date: course_info[:course].end_date,
                          new_users: course_info[:extended_course_stat].new_users)
      x.save
    end
      puts @all_course_infos
  end
end
