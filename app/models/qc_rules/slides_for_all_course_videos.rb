# frozen_string_literal: true

module QcRules
  class SlidesForAllCourseVideos
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      return unless started?(course)
      return if course['status'] != 'preparation'

      video_titles = videos_without_thumbnails(course)
      if video_titles.empty?
        @rule.alerts_for(course_id: course['id']).close!
      else
        @rule.alerts_for(course_id: course['id']).open!(
          severity: 'high',
          annotation: "Slide based Navigation #{video_titles.join ', '}",
        )
      end
    end

    private

    def started?(course)
      return false unless course['start_date']

      (course['start_date'].to_datetime - 2.days).past?
    end

    def videos_without_thumbnails(course)
      result = []

      Xikolo.paginate(
        course_service.rel(:items).get(course_id: course['id'], content_type: 'video'),
      ) do |item|
        next if item['content_id'].blank?

        video = video_service.rel(:video).get(id: item['content_id']).value!

        result << video['title'] if video['thumbnail_archive_id'].blank?
      end

      result
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def video_service
      @video_service ||= Restify.new(:video).get.value!
    end
  end
end
