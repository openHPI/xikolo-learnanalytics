class DifficultSelftestWorker < QcRuleWorker
  def perform(course, rule_id)
    puts " Kurs: #{course.course_code}"
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
        puts "Quiz Item: #{quiz_item.id}"
        quiz_submission_statistic = Xikolo::Submission::QuizSubmissionStatistic.find(quiz_item.content_id)
        Acfs.run
        quiz_submission_statistic.questions.each do |question|
          question.each do |question_id, question_info|
            check_wrong_answers(quiz_item.id, course.id,  question_id, question_info, rule_id, severity)
            check_sum_wrong_answers(quiz_item.id, course.id,  question_id, question_info, rule_id, severity)
          end
        end
      end
    end
    # for all self tests, graded homeworks, bonus homworks (not for surveys) for all published courses
  end

  def check_wrong_answers(quiz_item_id, course_id,  question_id, question_info, rule_id, severity)
    #new:
    #Wenn eine falsche Antwort häufiger angeklickt wurde als eine richtige Antwort,
    # sollte es eine Warnung geben (zeigt i.d.R. an, dass Regrading notwendig ist)
    highest_correct_answer = 0
    wrong_answers = []
    answers = question_info["answers"]
    answers.each do |answer_id, answer|
      submission_count_answer = answer["count"]
      answer_data = Xikolo::Quiz::Answer.find(answer_id)
      Acfs.run
      if answer_data.correct
        highest_correct_answer = [submission_count_answer, highest_correct_answer].max
      else
        wrong_answers << submission_count_answer
      end
    end
    puts wrong_answers.to_s
    puts "Highest correct answer: #{highest_correct_answer}"
    if (wrong_answers.max || 0) >=  highest_correct_answer
      puts "BAM! Ther is something"
      qc_alert_data = create_json(quiz_item_id, question_id)
      quiz_question = Xikolo::Quiz::Question.find(question_id)
      Acfs.run
      question_title = Xikolo::RichText::RichText.find(quiz_question.question_rtid)
      Acfs.run
      annotation = "Question: #{question_title.markup[0...10]} (might need regrading)"
      puts annotation
      update_or_create_qc_alert_with_data(rule_id, course_id, severity, annotation, question_id, qc_alert_data)
    else
      find_and_close_qc_alert_with_data(rule_id, course_id, question_id)
    end
  end

  def check_sum_wrong_answers(quiz_item_id, course_id, question_id, question_info, rule_id, severity)
    #Wenn die Summe der Klicks zu richtigen Antworten weniger als 70% aller Klicks zu einer Frage ausmachen,
    # dann sollte es zu dieser Frage ebenfalls eine Warnung geben.
    threshold = 0.7
    clicks_correct_answer = 0
    submission_count_question = question_info['count']

    puts "Total submissions: #{submission_count_question}"
    answers = question_info["answers"]

    answers.each do |answer_id, answer|
      submission_count_answer = answer["count"]
      answer_data = Xikolo::Quiz::Answer.find(answer_id)
      Acfs.run
      if answer_data.correct
        clicks_correct_answer += submission_count_answer
      end
    end

    if clicks_correct_answer <= (threshold * submission_count_question)
      qc_alert_data = create_json(quiz_item_id, question_id)
      puts " BAM!"
      quiz_question = Xikolo::Quiz::Question.find(question_id)
      Acfs.run
      question_title = Xikolo::RichText::RichText.find(quiz_question.question_rtid)
      Acfs.run
      annotation = "Question: #{question_title.markup[0...10]} (less than 70% clicks on correct answer)"

      update_or_create_qc_alert_with_data(rule_id, course_id, severity, annotation, question_id, qc_alert_data)
    else
      find_and_close_qc_alert_with_data(rule_id, course_id, question_id)
    end
  end

private

  def create_json(resource_id, quiz_item_id)
    {"resource_id" => resource_id, "quiz_item_id" => quiz_item_id.to_s}
  end

end