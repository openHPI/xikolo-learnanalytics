# frozen_string_literal: true

module Reports
  class SubmissionReport < Base
    class << self
      def form_data
        {
          type: :submission_report,
          name: I18n.t(:'reports.submission_report.name'),
          description: I18n.t(:'reports.submission_report.desc'),
          scope: {
            type: 'text_field',
            name: :task_scope,
            label: I18n.t(:'reports.submission_report.options.quiz_id'),
            options: {
              placeholder: I18n.t(:'reports.submission_report.options.quiz_id_placeholder'),
              input_size: 'large',
              required: true,
            },
          },
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.shared_options.machine_headers'),
            },
            {
              type: 'checkbox',
              name: :de_pseudonymized,
              label: I18n.t(:'reports.shared_options.de_pseudonymized'),
            },
            {
              type: 'text_field',
              name: :zip_password,
              label: I18n.t(:'reports.shared_options.zip_password'),
              options: {
                placeholder: I18n.t(:'reports.shared_options.zip_password_placeholder'),
                input_size: 'large',
              },
            },
          ],
        }
      end
    end

    def initialize(job)
      super

      @de_pseudonymized = job.options['de_pseudonymized']
    end

    def generate!
      @job.update(
        annotation: "#{course['course_code']}_" \
                    "#{item['title'].parameterize.underscore} " \
                    "(#{@job.task_scope})",
      )

      csv_file("SubmissionReport_#{course['course_code']}_#{@job.task_scope}", headers) do |&write|
        each_submission(&write)
      end
    end

    private

    def headers
      headers = [@de_pseudonymized ? 'User ID' : 'User Pseudo ID']

      if @de_pseudonymized
        headers.push(
          'User Name',
          'Email',
        )
      end

      headers.push(
        'Accessed At',
        'Submitted At',
        'Submit Duration',
        'Points',
      )

      headers.concat(
        all_quiz_questions.flat_map do |_, question|
          [
            question[:question_text].squish,
            *question[:answers].map {|answer| answer[:answer_text].squish },
          ]
        end,
      )
    end

    def each_submission
      submissions_counter = 0
      progress.update(item['content_id'], 0)

      submissions_promise = Xikolo.paginate_with_retries(
        max_retries: 3, wait: 60.seconds,
      ) do
        quiz_service.rel(:quiz_submissions).get({
          quiz_id: @job.task_scope,
          only_submitted: true,
        })
      end

      submissions_promise.each_item do |submission, page|
        submission_hash = Hash.new {|h, k| h[k] = Hash.new(&h.default_proc) }
        submission_hash[:accessed_at] =
          DateTime.parse(submission['quiz_access_time'])
        submission_hash[:submitted_at] =
          DateTime.parse(submission['quiz_submission_time'])
        submission_hash[:submit_duration] =
          submission_hash[:submitted_at].to_i -
          submission_hash[:accessed_at].to_i
        submission_hash[:user_id] = submission['user_id']

        user = account_service.rel(:user).get({id: submission['user_id']}).value!
        submission_hash[:user_name] = escape_csv_string(user['full_name'])
        submission_hash[:user_email] = user['email']

        submission_hash[:points] = submission['points']

        quiz_service.rel(:quiz_submission_questions).get({
          quiz_submission_id: submission['id'],
          per_page: 250,
        }).value!.each do |submission_question|
          submission_hash[:questions][submission_question['quiz_question_id']][:selected_answers] = []

          quiz_service.rel(:quiz_submission_answers).get({
            quiz_submission_question_id: submission_question['id'],
            per_page: 500,
          }).value!.each do |submission_answer|
            if submission_answer['type'] == 'Xikolo::Submission::QuizSubmissionFreeTextAnswer'
              submission_hash[:questions][submission_question['quiz_question_id']][:freetext_answer] =
                submission_answer['user_answer_text'].squish
            else
              submission_hash[:questions][submission_question['quiz_question_id']][:selected_answers] <<
                submission_answer['quiz_answer_id']
              submission_hash[:questions][submission_question['quiz_question_id']][:freetext_answer] = ''
            end
          end
        end

        yield transform_submission(submission_hash)

        submissions_counter += 1
        progress.update(
          item['content_id'],
          submissions_counter,
          max: page.response.headers['X_TOTAL_COUNT'].to_i,
        )
      end
    end

    def transform_submission(row)
      values = [
        if @de_pseudonymized
          row[:user_id]
        else
          Digest::SHA256.hexdigest(row[:user_id])
        end,
      ]

      if @de_pseudonymized
        values += [
          row[:user_name],
          row[:user_email],
        ]
      end

      values += [
        row[:accessed_at],
        row[:submitted_at],
        row[:submit_duration],
        row[:points],
      ]

      values + all_quiz_questions.flat_map do |key, question|
        # Special case: Essay questions do not have answer objects, thus the
        # following +map+ would have no effect.
        next [row[:questions][key][:freetext_answer]] if question[:answers].empty?

        # For each question, we add an empty column (for the quiz question)
        # and one column for each possible answer.
        # rubocop:disable Performance/CollectionLiteralInLoop
        [''] + question[:answers].map do |answer|
          if row[:questions][key][:selected_answers].include? answer[:id]
            '1'
          else
            row[:questions][key][:freetext_answer]
          end
        end
      end
    end
    # rubocop:enable all

    def all_quiz_questions
      @all_quiz_questions ||= load_all_quiz_questions
    end

    def load_all_quiz_questions
      hash = Hash.new {|h, k| h[k] = Hash.new(&h.default_proc) }

      quiz = quiz_service.rel(:quiz).get({id: @job.task_scope}).value!
      quiz_questions = quiz_service.rel(:questions).get({
        quiz_id: quiz['id'],
        per_page: 250,
      }).value!

      quiz_questions.each do |quiz_question|
        hash[quiz_question['id']][:question_text] = quiz_question['text']

        hash[quiz_question['id']][:answers] = []

        answers_promise = Xikolo.paginate_with_retries(
          max_retries: 3, wait: 60.seconds,
        ) do
          quiz_service.rel(:answers).get({
            question_id: quiz_question['id'],
            per_page: 250,
          })
        end

        answers_promise.each_item do |quiz_answer|
          hash[quiz_question['id']][:answers] << {
            id: quiz_answer['id'],
            position: quiz_answer['position'],
            answer_text: quiz_answer['text'],
          }
        end

        hash[quiz_question['id']][:answers].sort_by! do |answer|
          answer[:position]
        end
      end

      hash
    end

    def item
      @item ||= course_service.rel(:items)
        .get({content_id: @job.task_scope}).value!.first.tap do |item|
        raise 'Quiz not found. Did you provide the Item ID instead of the Content ID?' if item.nil?
      end
    end

    def course
      @course ||= course_service.rel(:course).get({id: item['course_id']}).value!
    end

    def account_service
      @account_service ||= Restify.new(:account).get.value!
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def quiz_service
      @quiz_service ||= Restify.new(:quiz).get.value!
    end
  end
end
