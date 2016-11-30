class DifficultSelftestWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'medium'
    quiz_items = []
    # for all self tests, graded homeworks, bonus homworks (not for surveys) for all published courses
    if course_is_active(course)
      Xikolo::Course::Item.each_item(:content_type => 'quiz', exercise_type: %w(main bonus selftest), :course_id => course.id, :published => 'true') do |quiz_item|
        quiz_items << quiz_item
      end
      Acfs.run
      # content_id => quiz_id
      quiz_items.each do |quiz_item|
        quiz_submission_statistic = Xikolo::Submission::QuizSubmissionStatistic.find(quiz_item.content_id)
        Acfs.run
        quiz_submission_statistic.questions.each do |question|
          question.each do |question_id, question_info|
            check_for_difficult_selftest(course, question_id, question_info, quiz_item, rule_id, severity)
          end
        end
      end
    end
  end

  def check_for_difficult_selftest(course, question_id, question_info, quiz_item, rule_id, severity)
    minimum_submissions = 20
    right_answers_threshold = 0.7 # put in Xikolo config
    clicks_correct_answer = 0

    highest_correct_answer_submission_count = 0
    wrong_answers_submission_counts = []

    submission_count_question = question_info["count"]
    if submission_count_question > minimum_submissions
      answers = question_info["answers"]
      answers.each do |answer_id, answer|
        answer_submission_count = answer["count"]
        quiz_answer = Xikolo::Quiz::Answer.find(answer_id)
        Acfs.run
        if quiz_answer.correct
          clicks_correct_answer += answer_submission_count
          highest_correct_answer_submission_count = [answer_submission_count, highest_correct_answer_submission_count].max
        else
          wrong_answers_submission_counts << answer_submission_count
        end
      end
      if (wrong_answers_submission_counts.max || 0) >= highest_correct_answer_submission_count or clicks_correct_answer <= (right_answers_threshold * submission_count_question)
        qc_alert_data = create_json(question_id, quiz_item.id,)
        quiz_question = Xikolo::Quiz::Question.find(question_id)
        Acfs.run
        question_title = Xikolo::RichText::RichText.find(quiz_question.question_rtid)
        Acfs.run
        annotation = "Question: '#{question_title.markup[0...20]}[..]'"
        update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, question_id, qc_alert_data)
      else
        find_and_close_qc_alert_with_data(rule_id, course.id, question_id)
      end
    end
  end

private

  def create_json(resource_id, quiz_item_id)
    #resource_id => question_id
    {"resource_id" => resource_id, "quiz_item_id" => quiz_item_id.to_s}
  end
end