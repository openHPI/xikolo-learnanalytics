module QcRules
  class QuizPerformance
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      Xikolo.paginate(
        course_service.rel(:items).get(
          content_type: 'quiz',
          course_id: course['id'],
          published: true,
          exercise_type: %w[main selftest]
        )
      ) do |item|
        quiz_performance = calculate_metrics(item, course)

        next unless quiz_performance
        next if quiz_performance[:total] < 10

        avg_attempts_too_high = quiz_performance[:avg_attempts].round(2) >= config['avg_attempts_threshold']
        avg_points_too_low = quiz_performance[:average_points_percentage].round(2) <= config['avg_percentage_threshold']
        first_attempt_too_low = quiz_performance[:average_points_percentage_first_attempt].round(2) <= config['avg_first_attempt_percentage_threshold']

        if avg_attempts_too_high or avg_points_too_low or first_attempt_too_low
          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: item['id'])
            .open!(
              severity: 'medium',
              annotation: "Quiz performance on #{item['title']} low: avg attempts #{quiz_performance[:avg_attempts].round(2)}, avg_performance: #{quiz_performance[:average_points_percentage].round(2)}, first_attempt_avg: #{quiz_performance[:average_points_percentage_first_attempt].round(2)}"
            )
        else
          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: item['id'])
            .close!
        end
      end
    end

    private

    def config
      @config ||= Xikolo.config.qc_alert['quiz_performance']
    end

    def calculate_metrics(item, course)
      Lanalytics::Metric::QuizPerformance.query(
        nil,
        course['id'],
        nil,
        nil,
        item['id'],
        nil,
        nil
      )
    end

    def course_service
      Xikolo.api(:course).value!
    end
  end
end
