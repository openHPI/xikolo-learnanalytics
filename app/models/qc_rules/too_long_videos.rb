# frozen_string_literal: true

module QcRules
  class TooLongVideos
    def initialize(rule)
      @rule = rule
    end

    def run(course)
      if course['end_date']&.to_date&.past?
        @rule.alerts_for(course_id: course['id']).close!
        return
      end

      return unless %w[active archive].include?(course['status'])

      Xikolo.paginate(
        course_service.rel(:items).get(
          course_id: course['id'],
          content_type: 'video',
          published: true,
        ),
      ) do |item|
        video = video(item['content_id'])
        duration_in_min = duration_in_min(video)

        if duration_in_min < config['low']
          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: item['id'])
            .close!
        else
          video_annotation = "Video is too long (#{duration_in_min} min): #{video['title']}"

          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: item['id'])
            .open!(
              severity: severity_for(duration_in_min),
              annotation: video_annotation,
            )
        end
      end
    end

    private

    def video(video_id)
      return unless video_id

      video_service.rel(:video).get(id: video_id).value!
    end

    def duration_in_min(video)
      return 0 unless video && video['duration']

      video['duration'] / 60
    end

    def severity_for(duration_in_min)
      if duration_in_min.between?(config['low'], config['medium'])
        'low'
      elsif duration_in_min.between?(config['medium'], config['high'])
        'medium'
      elsif duration_in_min > config['high']
        'high'
      end
      # Lower than low is already taken care of, no else needed
    end

    def config
      Lanalytics.config.qc_alert['video_duration']
    end

    def course_service
      @course_service ||= Restify.new(:course).get.value!
    end

    def video_service
      @video_service ||= Restify.new(:video).get.value!
    end
  end
end
