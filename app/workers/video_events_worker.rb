class VideoEventsWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'low'
    items = []
    if course_is_active(course)
      Xikolo::Course::Item.each_item(:content_type => 'video', :course_id => course.id, :published => 'true') do |item|
        items << item
      end
      Acfs.run
      items.each do |item|
        video_result = calculate_metrics(item)
        unless video_result.empty?
          video_positions = video_result.map { |s| convert_seconds_to_time(s) }
          annotation = "Many Pause/Play Events in '#{item.title}' at positions: #{video_positions.join(', ')}"
          qc_alert_data = create_json(item.id, video_result)
          update_or_create_qc_alert_with_data(rule_id, course.id, severity, annotation, item.id, qc_alert_data)
        else
          find_and_close_qc_alert_with_data(rule_id, course.id, item.id)
        end
      end
    end
  end

  private

  def create_json(resource_id, array)
    {"resource_id" => resource_id, "video_events" => array.to_s}
  end

  def calculate_metrics(item)
    threshold_percentage = 0.20 # percentage
    video_events = Lanalytics::Metric::VideoEvents.query(
        nil,
        nil,
        nil,
        nil,
        item.id,
        nil,
        nil)
    start_pause_time = {}
    start_value = 0
    video_events.each_with_index do |video_event, index|
      if index == 0
        start_value = video_event[1]["play"] unless video_event[1]["play"].nil?
      end
      pause_count = 0
      pause_count = video_event[1]["pause"] unless video_event[1]["pause"].nil?
      play_count = 0
      play_count = video_event[1]["play"] unless video_event[1]["play"].nil?
      pause_play_sum = pause_count + play_count
      start_pause_time[video_event[1]["time"]] = pause_play_sum
    end
    threshold = start_value * threshold_percentage
    final_result = []
    start_pause_time.each do |time, result|
      if result > threshold
        final_result.push(time)
      end
    end

    final_result.slice(1..-2).to_a
  end

  def convert_seconds_to_time(seconds)
    total_minutes = seconds / 1.minutes
    seconds_in_last_minute = seconds - total_minutes.minutes.seconds
    "#{total_minutes}m#{seconds_in_last_minute}s"
  end
end