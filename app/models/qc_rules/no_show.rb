module QcRules
  class NoShow
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      return false unless active?(course)

      no_show_rate = no_show_rate_for(course)
      if no_show_rate >= threshold_for(course['start_date'].to_datetime)
        @rule.alerts_for(course_id: course['id']).open!(
          severity: 'medium',
          annotation: "High no-show rate: #{no_show_rate}"
        )
      else
        @rule.alerts_for(course_id: course['id']).close!
      end
    end

    private

    def active?(course)
      return false if course['start_date'].blank? || course['end_date'].blank?

      return false unless course['status'] == 'active'

      course['start_date'].to_datetime.past? && course['end_date'].to_datetime.future?
    end

    def no_show_rate_for(course)
      course_stats = course_service.rel(:stats).get(
        course_id: course['id'], key: 'extended'
      ).value!

      enrollments = course_stats['student_enrollments']
      no_shows = course_stats['no_shows']

      if enrollments.to_f == 0
        0
      else
        (no_shows * 100 / enrollments.to_f).round(2)
      end
    end

    def threshold_for(start_date)
      # 1-2 days after course start
      if DateTime.now.between?(start_date + 24.hours, start_date + 48.hours)
        config['24_hours']
      # 2-7 days after course start
      elsif DateTime.now.between?(start_date + 48.hours, start_date + 7.days)
        config['48_hours']
      # More than 7 days after course start
      elsif DateTime.now >= start_date + 7.days
        config['7_days']
      # First day
      else
        0
      end
    end

    def config
      Lanalytics.config.qc_alert['no_show_rate']
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end
  end
end
