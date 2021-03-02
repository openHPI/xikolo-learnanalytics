# frozen_string_literal: true

module Reports
  # rubocop:disable Metrics/ClassLength
  class PinboardReport < Base
    def initialize(job)
      super

      @de_pseudonymized = job.options['de_pseudonymized']
      @include_collab_spaces = job.options['include_collab_spaces']
      @include_permission_groups = job.options['include_permission_groups']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file(
        "PinboardReport_#{course['course_code']}",
        headers,
        &method(:each_post)
      )
    end

    private

    def headers
      headers = [
        'ID',
        'Title',
        'Text',
        'Video Timestamp',
        'Video ID',
        @de_pseudonymized ? 'User ID' : 'User Pseudo ID',
        'Created At',
        'Updated At',
        'Accepted Answer ID',
        'Course ID',
        'Collab Space ID',
        'Collab Space Title',
        'Topic ID',
        'File ID',
        'Commentable ID',
        'Commentable Type',
        'Answer Prediction',
        'Sentiment',
        'Sticky',
        'Deleted',
        'Closed',
        'Section ID',
        'Section Title',
        'Item ID',
        'Item Title',
      ]

      if @include_permission_groups
        headers.concat [
          'User Global Groups',
          'User Course Groups',
        ]
      end

      headers
    end

    def each_post
      i = 0

      each_topic do |topic, page|
        yield transform_topic(topic)

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

    def transform_topic(topic)
      section_id = implicit_section_id(topic['implicit_tags'])
      item_id = implicit_item_id(topic['implicit_tags'])

      section_title = sections
        .find {|section| section['id'] == section_id }&.dig('title')
      item_title = items
        .find {|item| item['id'] == item_id }&.dig('title')

      collab_space_id = topic['learning_room_id']
      collab_space_title = collab_spaces
        .find {|space| space['id'] == collab_space_id }&.dig('name')

      values = [
        topic['id'],
        topic['title'],
        topic['text'].squish,
        topic['video_timestamp'],
        topic['video_id'],
        user_id(topic['user_id']),
        topic['created_at'],
        topic['updated_at'],
        topic['accepted_answer_id'],
        topic['course_id'],
        collab_space_id,
        collab_space_title,
        topic['id'],
        '',
        '',
        '',
        '',
        topic['sentimental_value'],
        topic['sticky'],
        topic['deleted'],
        topic['closed'],
        section_id,
        section_title,
        item_id,
        item_title,
      ]

      if @include_permission_groups
        global_groups = user_global_groups
          .groups_for_user(topic['user_id'])
          .join(';')
        course_groups = user_course_groups
          .groups_for_user(topic['user_id'])
          .join(';')

        values.concat [
          global_groups,
          course_groups,
        ]
      end

      values
    end

    def each_topic(&block)
      topic_filters.each do |filters|
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          pinboard_service.rel(:questions).get(**filters, per_page: 50)
        end.each_item(&block)
      end
    end

    def each_answer(topic)
      pinboard_service.rel(:answers).get(
        question_id: topic['id'], per_page: 250,
      ).value!.each do |answer|
        yield [
          answer['id'],
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

    # rubocop:disable Metrics/BlockLength
    def each_comment(object, type)
      pinboard_service.rel(:comments).get(
        commentable_id: object['id'], commentable_type: type, per_page: 250,
      ).value!.each do |comment|
        question_id = ''
        if comment['commentable_type'] == 'Question'
          question_id = comment['commentable_id']
        elsif comment['commentable_type'] == 'Answer'
          question_id = object['question_id']
        end

        yield [
          comment['id'],
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
    # rubocop:enable all

    def user_id(id)
      if @de_pseudonymized
        id
      else
        Digest::SHA256.hexdigest(id)
      end
    end

    def implicit_section_id(tags)
      tags.find do |tag|
        tag['referenced_resource'] == 'Xikolo::Course::Section'
      end&.dig('name')
    end

    def implicit_item_id(tags)
      tags.find do |tag|
        tag['referenced_resource'] == 'Xikolo::Course::Item'
      end&.dig('name')
    end

    def topic_filters
      filters = [
        {course_id: course['id']},
      ]

      if @include_collab_spaces
        collab_spaces.each {|space| filters << {learning_room_id: space['id']} }
      end

      filters
    end

    def course
      @course ||= course_service.rel(:course).get(id: @job.task_scope).value!
    end

    def sections
      @sections ||= begin
        sections = []

        sections_promise = Xikolo.paginate_with_retries(
          max_retries: 3, wait: 60.seconds,
        ) do
          course_service.rel(:sections).get(course_id: course['id'])
        end

        sections_promise.each_item do |section|
          sections << section
        end

        sections
      end
    end

    def items
      @items ||= begin
        items = []

        items_promise = Xikolo.paginate_with_retries(
          max_retries: 3, wait: 60.seconds,
        ) do
          course_service.rel(:items).get(course_id: course['id'])
        end

        items_promise.each_item do |item|
          items << item
        end

        items
      end
    end

    def collab_spaces
      @collab_spaces ||= begin
        collab_spaces = []

        collab_spaces_promise = Xikolo.paginate_with_retries(
          max_retries: 3, wait: 60.seconds,
        ) do
          collab_space_service.rel(:collab_spaces).get(course_id: course['id'])
        end

        collab_spaces_promise.each_item do |space|
          collab_spaces << space
        end

        collab_spaces
      end
    end

    def user_global_groups
      @user_global_groups ||= UserGroups::GlobalGroups.new
    end

    def user_course_groups
      @user_course_groups ||= UserGroups::CourseGroups.new(
        course['course_code'],
      )
    end

    def collab_space_service
      @collab_space_service ||= Restify.new(:collabspace).get.value!
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def pinboard_service
      @pinboard_service ||= Restify.new(:pinboard).get.value!
    end
  end
end
