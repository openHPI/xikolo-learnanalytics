class DifficultSelftestWorker < QcRuleWorker
  def perform(course, rule_id)
    severity = 'medium'
    quiz_items = []
    annotation = ''
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
            check_under_average_question(course, question_id, question_info, rule_id, severity)
            check_wrong_answers(course, question_info, rule_id, severity)
          end
        end
      end
    end
    # for all self tests, graded homeworks, bonus homworks (not for surveys) for all published courses
  end

  def check_wrong_answers(course, question_info, rule_id, severity)
    # is any wrong answer checked by more of 50% of all users
    threshold_answers = 0.5
    answers = question_info["answers"]
    answers.each do |answer_id, answer|
      submission_count_answer = answer["count"]
      submission_count_question = question_info["count"]
      if submission_count_answer/submission_count_question.to_f >= threshold_answers
        puts "answer over threshold"
        answer_data = Xikolo::Quiz::Answer.find(answer_id)
        Acfs.run
        unless answer_data.correct
          puts "answer is not correct"

          answer_title = Xikolo::RichText::RichText.find(answer_data.answer_rtid)
          Acfs.run
          annotation = "Answer: #{answer_title.markup[0...10]}"
          qc_alert_data = create_json(quiz_item.id, nil, answer_data.id)
          update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, answer_data.id, qc_alert_data)
        else
          find_and_close_qc_alert_with_data(rule_id, course.id, answer_data.id)
        end
      else
        #find_and_close_qc_alert_with_data(rule_id, course.id, answer_data.id)
      end
    end
  end

  def check_under_average_question(course, question_id, question_info, rule_id, severity)
    # has any question average points less than 50%  (put value to config)
    average_points = question_info["avg_points"]
    quiz_question = Xikolo::Quiz::Question.find(question_id)
    Acfs.run
    question_title = Xikolo::RichText::RichText.find(quiz_question.question_rtid)
    Acfs.run

    points = quiz_question.points
    # has any question average points less than 50%  (put value to config)
    threshold = 0.5
    if average_points/points.to_f <= threshold
      puts ' question average is below 50%'
      qc_alert_data = create_json(quiz_item.id, quiz_question.id, nil)
      annotation = "Question: #{question_title.markup[0...10]}"
      update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, quiz_question.id, qc_alert_data)
    else
      find_and_close_qc_alert_with_data(rule_id, course.id, quiz_question.id)
    end
  end
end

private

def create_json(resource_id, question_id, answer_id)
  {"resource_id" => resource_id, "question_id" => question_id.to_s, "answer_id" => answer_id.to_s}
end