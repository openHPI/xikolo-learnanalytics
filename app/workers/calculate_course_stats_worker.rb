# frozen_string_literal: true

class CalculateCourseStatsWorker
  include Sidekiq::Worker

  def perform
    each_course do |course|
      gather_stats! course['id']
    end

    notify!
  end

  private

  def each_course
    Xikolo.paginate(
      course_service.rel(:courses).get(groups: 'any'),
    ) do |course|
      next if course['status'] == 'preparation' || course['external_course_url'].present?

      yield course
    end
  end

  def gather_stats!(course_id)
    CourseStatistic.find_or_create_by(course_id: course_id).tap(&:calculate!)
  end

  def notify!
    Msgr.publish({}, to: 'xikolo.lanalytics.course_stats.calculate')
  end

  def course_service
    @course_service ||= Restify.new(:course).get.value!
  end
end
