module QcRules
  class DifficultSelftest
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      return unless active?(course)

      # Evaluate all self tests, graded homeworks, bonus homeworks (ignore surveys)
      Xikolo.paginate(
        course_service.rel(:items).get(
          course_id: course['id'],
          content_type: 'quiz',
          exercise_type: %w[main bonus selftest],
          published: true
        )
      ) do |quiz_item|
        check_for_difficult_selftest(quiz_item)
      end
    end

    private

    def active?(course)
      return false if course['start_date'].blank? || course['end_date'].blank?

      return false unless course['status'] == 'active'

      course['start_date'].to_datetime.past? && course['end_date'].to_datetime.future?
    end

    def check_for_difficult_selftest(quiz_item)
      quiz_service.rel(:quiz_submission_statistic).get(
        id: quiz_item['content_id'],
        embed: 'questions'
      ).value!['questions'].each do |question|
        question.each do |question_id, submissions|
          next if submissions['count'] <= config['minimum_submissions']

          if too_many_wrong?(submissions)
            quiz_question = quiz_service.rel(:question).get(id: question_id).value!
            question_title = richtext_service.rel(:rich_text).get(id: quiz_question['question_rtid']).value!

            @rule.alerts_for(course_id: course['id'])
              .with_data(resource_id: question_id)
              .open!(
                severity: 'medium',
                annotation: "Question: '#{question_title['markup'][0...20]}[..]'",
                qc_alert_data: {'quiz_item_id' => quiz_item['id']}
              )
          else
            @rule.alerts_for(course_id: course['id'])
              .with_data(resource_id: question_id)
              .close!
          end
        end
      end
    end

    def too_many_wrong?(submissions)
      answers = submissions['answers'].keys
                  .map { |id| quiz_service.rel(:answer).get(id: id) }
                  .map(&:value!)

      correct_answers, wrong_answers = answers.partition { |answer| answer['correct'] }

      correct_answer_counts = correct_answers.map { |answer|
        submissions['answers'][answer['id']]['count']
      }
      highest_correct_answer_count = correct_answer_counts.max || 0
      clicks_correct_answer = correct_answer_counts.sum || 0

      wrong_answer_counts = wrong_answers.map { |answer|
        submissions['answers'][answer['id']]['count']
      }
      highest_wrong_answer_count = wrong_answer_counts.max || 0


      return true if highest_wrong_answer_count >= highest_correct_answer_count

      return true if clicks_correct_answer <= (config['right_answer_threshold'] * submissions['count'].to_f)

      false
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

    def quiz_service
      @quiz_service ||= Xikolo.api(:quiz).value!
    end

    def richtext_service
      @richtext_service ||= Xikolo.api(:richtext).value!
    end

    def config
      @config ||= Xikolo.config.qc_alert['difficult_selftest']
    end
  end
end
