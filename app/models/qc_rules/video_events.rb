module QcRules
  class VideoEvents

    # The percentage from which we consider the amount of play/pause events suspicious
    THRESHOLD_PERCENTAGE = 0.20

    def initialize(rule)
      @rule = rule
    end

    def run(course)
      return unless active?(course)

      Xikolo.paginate(
        course_service.rel(:items).get(
          course_id: course['id'],
          content_type: 'video',
          published: true
        )
      ) do |item|
        video_result = calculate_metrics(item)
        if video_result.empty?
          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: item['id'])
            .close!
        else
          video_positions = video_result.map { |s| convert_seconds_to_time(s) }
          @rule.alerts_for(course_id: course['id'])
            .with_data(resource_id: item['id'])
            .open!(
              severity: 'low',
              annotation: "Many Pause/Play Events in '#{item.title}' at positions: #{video_positions.join ', '}",
              qc_alert_data: {'video_events' => video_result.to_s}
            )
        end
      end
    end

    private

    def active?(course)
      return false if course['start_date'].blank? || course['end_date'].blank?

      return false unless course['status'] == 'active'

      course['start_date'].to_datetime.past? && course['end_date'].to_datetime.future?
    end

    def calculate_metrics(item)
      video_events = Lanalytics::Metric::VideoEvents.query(
        nil,
        nil,
        nil,
        nil,
        item['id'],
        nil,
        nil
      )

      start_pause_time = video_events.each_with_object({}) do |event, hash|
        pause_count = event[1]['pause'] || 0
        play_count = event[1]['play'] || 0
        hash[event[1]['time']] = pause_count + play_count
      end

      start_value = video_events.first[1]['play'] || 0
      threshold = start_value * THRESHOLD_PERCENTAGE

      start_pause_time
        .select { |_time, result| result > threshold }
        .keys
        .slice(1..-2) # Cut off first and last one
    end

    def convert_seconds_to_time(seconds)
      total_minutes = seconds / 1.minute
      seconds_in_last_minute = seconds - total_minutes.minutes.seconds
      "#{total_minutes}m#{seconds_in_last_minute}s"
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
