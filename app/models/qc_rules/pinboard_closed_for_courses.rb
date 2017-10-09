module QcRules
  class PinboardClosedForCourses
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      return false if course['status'] == 'preparation'

      if raise_alert?(course)
        @rule.alerts_for(course_id: course['id']).open!(
          severity: 'low',
          annotation: 'Pinboard still open in an archived course'
        )
      else
        @rule.alerts_for(course_id: course['id']).close!
      end
    end

    private

    def raise_alert?(course)
      return false if active?(course)

      !course['forum_is_locked']
    end

    def active?(course)
      return false if course['start_date'].blank? || course['end_date'].blank?

      return false unless course['status'] == 'active'

      course['start_date'].to_datetime.past? && course['end_date'].to_datetime.future?
    end
  end
end
