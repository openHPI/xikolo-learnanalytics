# frozen_string_literal: true

class CalculateCourseStatsWorker
  include Sidekiq::IterableJob

  def build_enumerator(**)
    course_ids = [].tap do |ids|
      each_course {|course| ids << course['id'] }
    end
    array_enumerator(course_ids, **)
  end

  def each_iteration(course_id, *)
    # Re-calculate the course statistics for the course
    CourseStatistic.find_or_create_by(course_id:).tap(&:calculate!)
  end

  def on_complete
    # Notify xi-notification to send out the statistic email
    Msgr.publish({}, to: 'xikolo.lanalytics.course_stats.calculate')
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

  def course_service
    @course_service ||= Restify.new(:course).get.value!
  end
end
