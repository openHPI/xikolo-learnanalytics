module QcRules
  class PinboardClosedForCourses
    def initialize(rule)
      @rule = rule
    end

    def run(course)
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
      course['status'] == 'archive' && !course['forum_is_locked']
    end
  end
end
