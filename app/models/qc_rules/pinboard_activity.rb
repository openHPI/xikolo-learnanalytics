module QcRules
  class PinboardActivity
    # The percentage of users that should take part in the forum activity in the last week
    THRESHOLD = 0.025

    def initialize(rule)
      @rule = rule
    end

    def run(course)
      unless active?(course)
        @rule.alerts_for(course_id: course['id']).close!
        return
      end

      total_enrollments = enrollment_count(course)
      if total_enrollments >= 100 and course['start_date'].to_datetime < 2.day.ago
        activity = calculate_activity(course, total_enrollments)

        if activity < THRESHOLD
          @rule.alerts_for(course_id: course['id']).open!(
            severity: severity(activity, THRESHOLD),
            annotation: "Norm. activity #{activity}"
          )
        else
          @rule.alerts_for(course_id: course['id']).close!
        end
      end
    end

    private

    def active?(course)
      return false if course['start_date'].blank? || course['end_date'].blank?

      return false unless course['status'] == 'active'

      course['start_date'].to_datetime.past? && course['end_date'].to_datetime.future?
    end

    def enrollment_count(course)
      course_service.rel(:enrollments)
        .get(course_id: course['id'], per_page: 1)
        .value!
        .response
        .headers['X_TOTAL_PAGES']
        .to_i
    end

    def activity_count(course, start_time)
      Lanalytics::Metric::PinboardActivity.query(
        course_id: course['id'],
        start_date: start_time.iso8601,
        end_date: Time.now.iso8601
      )[:count]
    end

    def calculate_activity(course, total_enrollments)
      start_time_for_activity = [course['start_date'].to_datetime, 7.days.ago.to_datetime].max
      activity = activity_count(course, start_time_for_activity)
      course_analysis_time = Date.today - start_time_for_activity

      # Normalize to the length of the analyzed period
      activity / (total_enrollments.to_f * course_analysis_time.to_f)
    end

    def severity(activity, threshold)
      if activity < threshold / 2
        'medium'
      elsif activity < threshold / 4
        'high'
      else
        'low'
      end
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end
  end
end
