class AdminStatistic < ActiveRecord::Base
  #attr_reader :all_course_infos, :general_course_statistic
=begin
  def initialize
    @all_course_infos = []
    courses = []
    Xikolo::Course::Course.each_item(affiliated: true) do | course |
      next if course.status == 'preparation' or !course.external_course_url.blank?
      courses << course
    end
    Acfs.run
    courses.each do |course|
      course_stat =  Xikolo::Course::Statistic.find course_id: course.id
      extended_course_stat =  Xikolo::Course::Stat.find course_id: course.id, key: 'extended'
      pinboard_course_stat =  Xikolo::Pinboard::Statistic.find course.id
      ticket_course_stat =  Xikolo::Helpdesk::Statistic.find course_id: course.id
      enrollments_per_day = Xikolo::Course::Stat.find course_id: course.id, key: 'enrollments_by_day'
      Acfs.run
      @all_course_infos << {
          course: course,
          pinboard_course_stat: pinboard_course_stat,
          enrollments_per_day: enrollments_per_day,
          course_stat: course_stat,
          extended_course_stat: extended_course_stat,
          helpdesk_stat: ticket_course_stat
      }
    end

  end
=end
end
