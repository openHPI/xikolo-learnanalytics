module Reports
  class PinboardReport < Base
    def initialize(job, options = {})
      super

      @deanonymized = options['deanonymized']
      @include_collab_spaces = options.fetch('include_collab_spaces', false)
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

      each_topic do |topic, page|
        pinboard_type = topic['discussion_flag'] ? 'discussion' : 'question'
        yield transform_topic(pinboard_type, topic)

        each_comment(topic, 'Question') do |row|
          yield row
        end

        unless topic['discussion_flag']
          each_answer(topic) do |row|
            yield row
          end
        end

        i += 1
        @job.progress_to(i, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def transform_topic(pinboard_type, topic)
      [
        topic['id'],
        pinboard_type,
        topic['title'],
        topic['text'].squish,
        topic['video_timestamp'],
        topic['video_id'],
        user_id(topic['user_id']),
        topic['created_at'],
        topic['updated_at'],
        topic['accepted_answer_id'],
        topic['course_id'],
        topic['learning_room_id'],
        topic['id'],
        '',
        '',
        '',
        '',
        topic['sentimental_value'],
        topic['sticky'],
        topic['deleted'],
        topic['closed'],
        implicit_section_id(topic['implicit_tags']),
        implicit_item_id(topic['implicit_tags'])
      ]
    end

    def each_topic(&block)
      topic_filters.each do |filters|
        Xikolo.paginate(
          pinboard_service.rel(:questions).get(**filters, per_page: 50),
          &block
        )
      end
    end

    def each_answer(topic)
      pinboard_service.rel(:answers).get(
        question_id: topic['id'], per_page: 250
      ).value!.each do |answer|
        yield [
          answer['id'],
          'answer',
          '',
          answer['text'].squish,
          '',
          '',
          user_id(answer['user_id']),
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
          comment['text'].squish,
          '',
          '',
          user_id(comment['user_id']),
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

    def user_id(id)
      if @deanonymized
        id
      else
        Digest::SHA256.hexdigest(id)
      end
    end

    def implicit_section_id(tags)
      tags.find { |tag| tag['referenced_resource'] == 'Xikolo::Course::Section' }&.dig('name')
    end

    def implicit_item_id(tags)
      tags.find { |tag| tag['referenced_resource'] == 'Xikolo::Course::Item' }&.dig('name')
    end

    def topic_filters
      filters = [
        {course_id: course['id']}
      ]

      if @include_collab_spaces
        Xikolo.paginate(
          collabspace_service.rel(:collab_spaces).get(course_id: course['id'])
        ) do |collab_space|
          filters << {learning_room_id: collab_space['id']}
        end
      end

      filters
    end

    def course
      @course ||= course_service.rel(:course).get(id: @job.task_scope).value!
    end

    def collabspace_service
      @collabspace_service ||= Xikolo.api(:learning_room).value!
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end

    def pinboard_service
      @pinboard_service ||= Xikolo.api(:pinboard).value!
    end
  end
end