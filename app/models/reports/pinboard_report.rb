module Reports
  class PinboardReport < Base
    def initialize(job, options = {})
      super

      @deanonymized = options['deanonymized']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file "PinboardReport_#{course['course_code']}", headers, &method(:each_post)
    end

    private

    def headers
      %w[
        id
        type
        title
        text
        video_timestamp
        video_id
        user_id
        created_at
        updated_at
        accepted_answer_id
        course_id
        learning_room_id
        question_id
        file_id
        commentable_id
        commentable_type
        answer_prediction
        sentiment
        sticky
        deleted
        closed
        section_id
        item_id
      ]
    end

    def each_post
      i = 0

      Xikolo.paginate(
        pinboard_service.rel(:questions).get(
          course_id: course['id'],
          per_page: 50
        )
      ) do |question, page|
        pinboard_type = question['discussion_flag'] ? 'discussion' : 'question'
        yield transform_question(pinboard_type, question)

        each_comment(question, 'Question') do |row|
          yield row
        end

        unless question['discussion_flag']
          each_answer(question) do |row|
            yield row
          end
        end

        i += 1
        @job.progress_to(i, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def transform_question(pinboard_type, question)
      [
        question['id'],
        pinboard_type,
        question['title'],
        question['text'].squish,
        question['video_timestamp'],
        question['video_id'],
        @deanonymized ? question['user_id'] : Digest::SHA256.hexdigest(question['user_id']),
        question['created_at'],
        question['updated_at'],
        question['accepted_answer_id'],
        question['course_id'],
        question['learning_room_id'],
        question['id'],
        '',
        '',
        '',
        '',
        question['sentimental_value'],
        question['sticky'],
        question['deleted'],
        question['closed'],
        implicit_section_id(question['implicit_tags']),
        implicit_item_id(question['implicit_tags'])
      ]
    end

    def each_answer(question)
      pinboard_service.rel(:answers).get(
        question_id: question['id'], per_page: 250
      ).value!.each do |answer|
        yield [
          answer['id'],
          'answer',
          '',
          answer['text'].squish,
          '',
          '',
          @deanonymized ? answer['user_id'] : Digest::SHA256.hexdigest(answer['user_id']),
          answer['created_at'],
          answer['updated_at'],
          '',
          '',
          '',
          answer['question_id'],
          answer['file_id'],
          '',
          '',
          answer['answer_prediction'],
          answer['sentimental_value'],
        ]

        # get comments for each answer
        each_comment(answer, 'Answer') do |row|
          yield row
        end
      end
    end

    def each_comment(object, type)
      pinboard_service.rel(:comments).get(
        commentable_id: object['id'], commentable_type: type, per_page: 250
      ).value!.each do |comment|
        question_id = ''
        if comment['commentable_type'] == 'Question'
          question_id = comment['commentable_id']
        elsif comment['commentable_type'] == 'Answer'
          question_id = object['question_id']
        end

        yield [
          comment['id'],
          'comment',
          '',
          comment['text'].squish ,
          '',
          '',
          @deanonymized ? comment['user_id'] : Digest::SHA256.hexdigest(comment['user_id']),
          comment['created_at'],
          comment['updated_at'],
          '',
          '',
          '',
          question_id,
          '',
          comment['commentable_id'],
          comment['commentable_type'],
          '',
          comment['sentimental_value'],
        ]
      end
    end

    def implicit_section_id(tags)
      tags.find { |tag| tag['referenced_resource'] == 'Xikolo::Course::Section' }&.dig('name')
    end

    def implicit_item_id(tags)
      tags.find { |tag| tag['referenced_resource'] == 'Xikolo::Course::Item' }&.dig('name')
    end

    def course
      @course ||= course_service.rel(:course).get(id: @job.task_scope).value!
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

    def pinboard_service
      @pinboard_service ||= Xikolo.api(:pinboard).value!
    end
  end
end