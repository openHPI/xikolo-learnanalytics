class CalculateSectionConversionsWorker
  include Sidekiq::Worker

  def perform
    each_course do |course|
      calculate! course['id']
    end
  end

  private

  def each_course
    Xikolo.paginate(
      course_service.rel(:courses).get(
        affiliated: true
      )
    ) do |course|
      next if course['status'] == 'preparation' or course['external_course_url'].present?
      yield course
    end
  end

  def calculate!(course_id)
    SectionConversion.find_or_create_by(course_id: course_id).tap do |conversions|
      conversions.calculate!
    end
  end

  def course_service
    @course_service ||= Xikolo.api(:course).value!
  end
end
