class CalculateCourseStatsWorker
  include Sidekiq::Worker

  def perform
    each_course do |course|
      gather_stats! course.id
    end

    notify!
  end

  private

  def each_course
    Xikolo::Course::Course.each_item(affiliated: true) do |course|
      next if course.status == 'preparation' or course.external_course_url.present?

      yield course
    end
    Acfs.run
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
