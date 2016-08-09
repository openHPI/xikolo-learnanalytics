class AdminStatisticsController < ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder
  respond_to :json

  def index
    admin_statistics = AdminStatistic.all
    if params['offset'].nil?
      @offset = 0
    elsif
    @offset = params['offset']
    end
    respond_with admin_statistics.offset(@offset)

  end

  def create
    puts "TADDDA"
    course_infos.each do |course_info|
      AdminStatistic.new(course_info[:course].title,
                         course_info[:course].course_code,
                         course_info[:course_stat].enrollments,
                         course_info[:extended_course_stat].no_shows,
                         course_info[:course_stat].current_enrollments,
                         course_info[:course_stat].last_day_enrollments,
                         course_info[:extended_course_stat].student_enrollments_at_start,
                         course_info[:extended_course_stat].student_enrollments_at_middle,
                         course_info[:extended_course_stat].student_enrollments_at_middle_netto,
                         course_info[:extended_course_stat].student_enrollments_at_end,
                         course_info[:pinboard_course_stat].questions,
                         course_info[:pinboard_course_stat].questions_last_day,
                         course_info[:pinboard_course_stat].answers,
                         course_info[:pinboard_course_stat].answers_last_day,
                         course_info[:pinboard_course_stat].comments_on_answers,
                         course_info[:pinboard_course_stat].comments_on_answers_last_day,
                         course_info[:pinboard_course_stat].comments_on_questions,
                         course_info[:pinboard_course_stat].comments_on_questions_last_day,
                         course_info[:extended_course_stat].certificates_count,
                         course_info[:helpdesk_stat].ticket_count,
                         course_info[:helpdesk_stat].ticket_count_last_day,
                         (course_info[:extended_course_stat].certificates_count.to_i > 0) ? "=(S"+(i+2).to_s+"/I"+(i+2).to_s + ") * 100" : '',
                         course_info[:course].start_date,
                         course_info[:course].end_date,
                         course_info[:extended_course_stat].new_users)
    end
  end
  def show
    if params[:course_id]
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
        AdminStatistic.all.create  course_object


      end
      puts @all_course_infos
    end


    respond_with ""
  end


end