class CalculateCourseStatsWorker
  include Sidekiq::Worker

  def perform
    each_course do |course|
      gather_stats! course.id
    end

    notify!
  end

  private

  def each_course(&block)
    courses = []

    Xikolo::Course::Course.each_item(affiliated: true) do |course|
      next if course.status == 'preparation' or course.external_course_url.present?

      courses << course
    end
    Acfs.run

    # We first gather all courses, and then loop over them again, to prevent problems with
    # other Acfs calls being executed inside the `each_item` loop. :headdesk:
    courses.each(&block)
  end

  def gather_stats!(course_id)
    CourseStatistic.find_or_create_by(course_id: course_id).tap do |stat|
      stat.calculate!
    end
  end

  def notify!
    Msgr.publish Hash.new, to: 'xikolo.lanalytics.course_stats.calculate'
  end
end
