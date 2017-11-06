class CheckAllRulesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    # Global rules
    CheckGlobalRulesWorker.perform_async

    # Course-specific rules
    Xikolo.paginate(
      course_service.rel(:courses).get(affiliated: true, public: true)
    ) do |course|
      # We might want to run checks for external courses too later, so we fetch them
      next if course['external_course_url'].present?

      CheckCourseRulesWorker.perform_async course['id']
    end
  end

  def course_service
    Xikolo.api(:course).value!
  end
end