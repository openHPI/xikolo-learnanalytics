module QcRules
  class LowCourseCommunication
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      return unless active?(course)
      return unless started_a_while_ago?(course)
      return unless has_enrollments?(course)

      announcement = news_service.rel(:news_index).get(
        course_id: course['id'],
        published: true,
        page: 1,
        per_page:1
      ).value!.first

      if announcement && announcement['publish_at'].to_datetime > 10.days.ago
        @rule.alerts_for(course_id: course['id']).close!
      else
        @rule.alerts_for(course_id: course['id']).open!(
          severity: 'low',
          annotation: announcement ? "Last announcement #{announcement['publish_at'].to_datetime.to_formatted_s(:short)}" : 'No announcement'
        )
      end
    end

    private

    def active?(course)
      return false if course['start_date'].blank? || course['end_date'].blank?

      return false unless course['status'] == 'active'

      course['start_date'].to_datetime.past? && course['end_date'].to_datetime.future?
    end

    def started_a_while_ago?(course)
      course['start_date'].to_datetime < 10.days.ago
    end

    def has_enrollments?(course)
      course_service.rel(:enrollments)
        .get(course_id: course['id'], per_page: 1)
        .value!
        .response
        .headers['X_TOTAL_PAGES']
        .to_i > 0
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def news_service
      @news_service ||= Restify.new(:news).get.value!
    end
  end
end
