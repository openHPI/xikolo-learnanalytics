# frozen_string_literal: true

module QcRules
  class DifficultQuestion
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      return unless active?(course)

      Xikolo.paginate(
        course_service.rel(:items).get(
          course_id: course['id'],
          content_type: 'quiz',
          exercise_type: 'main,bonus,selftest', # ignore surveys
          published: true,
        ),
      ) do |quiz_item|
        check_for_difficult_question(quiz_item, course)
      end
    end

    private

    def active?(course)
      return false if course['start_date'].blank? ||
                      course['end_date'].blank?

      return false unless course['status'] == 'active'

      course['start_date'].to_datetime.past? &&
        course['end_date'].to_datetime.future?
    end

    def check_for_difficult_question(quiz_item, course)
      quiz_service.rel(:submission_statistic).get(
        id: quiz_item['content_id'],
        embed: 'questions_base_stats',
      ).value!['questions_base_stats'].each do |stats|
        total_submissions = stats['correct_submissions'] +
                            stats['incorrect_submissions'] +
                            stats['partly_correct_submissions']

        next if total_submissions <= config['minimum_submissions']

        if too_many_wrong?(stats)
          question = quiz_service.rel(:question).get(id: stats['id']).value!

          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: stats['id'])
            .open!(
              severity: 'medium',
              annotation: "Question: '#{question['text'][0...20]}[..]'",
              qc_alert_data: {quiz_item_id: quiz_item['id']},
            )
        else
          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: stats['id'])
            .close!
        end
      end
    end

    def too_many_wrong?(stats)
      correct_submissions = stats['correct_submissions']

      wrong_submissions = stats['incorrect_submissions'] +
                          stats['partly_correct_submissions']

      correct_submissions_ratio = correct_submissions.to_f /
                                  (correct_submissions + wrong_submissions)

      return true if correct_submissions_ratio <=
                     config['correct_submissions_threshold']

      false
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def quiz_service
      @quiz_service ||= Restify.new(:quiz).get.value!
    end

    def config
      @config ||= Lanalytics.config.qc_alert['difficult_quiz_question']
    end
  end
end
