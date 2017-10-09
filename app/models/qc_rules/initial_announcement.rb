module QcRules
  class InitialAnnouncement
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      if raise_alert?(course)
        @rule.alerts_for(course_id: course['id']).open!(
          severity: course['start_date'].to_datetime < 4.business_days.from_now ? 'high' : 'low',
          annotation: 'No initial mail announcement before course start'
        )
      else
        @rule.alerts_for(course_id: course['id']).close!
      end
    end

    private

    def raise_alert?(course)
      # Ignore courses that have already ended
      return false if course['end_date'].present? && course['end_date'].to_datetime.past?

      # Ignore courses that have no start date or start in the future
      return false if course['start_date'].blank? || course['start_date'].to_datetime >= 7.business_days.from_now

      # Ignore courses that don't have enough enrollments
      return false if enrollment_count(course) <= 1

      # If we get here, we raise an alert if no mail was sent before the course started
      no_start_announcement?(course)
    end

    def no_start_announcement?(course)
      Xikolo.paginate(
        news_service.rel(:news_index).get(course_id: course['id'], published: true)
      ) do |announcement|
        next if announcement['publish_at'].blank?
        next if announcement['sending_state'].to_i == 0
        next if announcement['publish_at'].to_datetime > course['start_date'].to_datetime

        # We found a candidate for an initial announcement
        return false
      end

      # If we get here, we found no matching announcement
      true
    end

    def enrollment_count(course)
      course_service.rel(:enrollments)
        .get(course_id: course['id'], per_page: 1)
        .value!
        .response
        .headers['X_TOTAL_PAGES']
        .to_i
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

    def news_service
      @news_service ||= Xikolo.api(:news).value!
    end
  end
end
