module Reports
  class SubmissionReport < Base
    def initialize(job, options = {})
      super

      @deanonymized = options['deanonymized']
    end

    def generate!
      @job.update(annotation: "#{item['title'].parameterize.underscore} (#{@job.task_scope})")

      csv_file "SubmissionReport_#{@job.task_scope}", headers, &method(:each_submission)
    end

    private

    def headers
      headers = ['User ID']

      if @deanonymized
        headers.concat [
         'User Name',
         'Email',
        ]
      end

      headers.concat [
        'Submitted On',
        'Points',
      ]

      headers.concat all_quiz_questions.flat_map { |_, question|
        [question[:question_text].squish, *question[:answers].map { |answer| answer[:answer_text].squish }]
      }
    end

    def each_submission
      i = 0
      Xikolo.paginate(
        quiz_service.rel(:quiz_submissions).get(
          quiz_id: @job.task_scope,
          only_submitted: true
        )
      ) do |submission, page|
        submission_hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        submission_hash[:created_at] = DateTime.parse(submission['quiz_submission_time'])
        submission_hash[:user_id] = submission['user_id']

        user = account_service.rel(:user).get(id: submission['user_id']).value!
        submission_hash[:user_name] = escape_csv_string(user['full_name'])
        submission_hash[:user_email] = user['email']

        submission_hash[:points] = submission['points']

        quiz_service.rel(:quiz_submission_questions).get(
          quiz_submission_id: submission['id'], per_page: 250
        ).value!.each do |submission_question|
          submission_hash[:questions][submission_question['quiz_question_id']][:selected_answers] = []

          quiz_service.rel(:quiz_submission_answers).get(
            quiz_submission_question_id: submission_question['id'], per_page: 500
          ).value!.each do |submission_answer|
            if 'Xikolo::Submission::QuizSubmissionFreeTextAnswer' == submission_answer['type']
              submission_hash[:questions][submission_question['quiz_question_id']][:freetext_answer] = submission_answer['user_answer_text'].squish
            else
              submission_hash[:questions][submission_question['quiz_question_id']][:selected_answers] << submission_answer['quiz_answer_id']
              submission_hash[:questions][submission_question['quiz_question_id']][:freetext_answer] = ''
            end
          end
        end

        yield transform_submission(submission_hash)

        i += 1
        @job.progress_to(i, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def transform_submission(row)
      values = [@deanonymized ? row[:user_id] : Digest::SHA256.hexdigest(row[:user_id])]

      if @deanonymized
        values += [
          row[:user_name],
          row[:user_email],
        ]
      end

      values += [
        row[:created_at],
        row[:points],
      ]

      values + all_quiz_questions.flat_map { |key, question|
        # Special case: Essay questions do not have answer objects, thus the
        # following +map+ would have no effect.
        if question[:answers].empty?
          next [row[:questions][key][:freetext_answer]]
        end

        # For each question, we add an empty column (for the quiz question)
        # and one column for each possible answer.
        [''] + question[:answers].map { |answer|
          if row[:questions][key][:selected_answers].include? answer[:id]
            '1'
          else
            row[:questions][key][:freetext_answer]
          end
        }
      }
    end

    def all_quiz_questions
      @all_quiz_questions ||= load_all_quiz_questions
    end

    def load_all_quiz_questions
      hash = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      quiz = quiz_service.rel(:quiz).get(id: @job.task_scope).value!
      quiz_questions = quiz_service.rel(:questions).get(
        quiz_id: quiz['id'],
        per_page: 250
      ).value!

      quiz_questions.each do |quiz_question|
        q_richtext = richtext_service.rel(:rich_text).get(id: quiz_question['question_rtid']).value!
        hash[quiz_question['id']][:question_text] = q_richtext['markup']

        hash[quiz_question['id']][:answers] = []

        Xikolo.paginate(
          quiz_service.rel(:answers).get(
            question_id: quiz_question['id'],
            per_page: 250
          )
        ) do |quiz_answer|
          a_richtext = richtext_service.rel(:rich_text).get(id: quiz_answer['answer_rtid']).value!
          hash[quiz_question['id']][:answers] << {
            id: quiz_answer['id'],
            position: quiz_answer['position'],
            answer_text: a_richtext['markup']
          }
        end

        hash[quiz_question['id']][:answers].sort_by! { |answer| answer[:position] }
      end

      hash
    end

    def item
      @item ||= course_service.rel(:items).get(content_id: @job.task_scope).value!.first
    end

    def account_service
      @account_service ||= Xikolo.api(:account).value!
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
  end
end
