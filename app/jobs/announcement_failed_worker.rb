class AnnouncementFailedWorker < QcRuleWorker

  def perform(course, rule_id)
    severity = 'high'
    allowed_delta = 10
    all_news = API[:news].rel(:news_index).get(published: "true").value!
    all_news.each do |announcement|
      course_id = announcement['course_id']
      if announcement['publish_at'].present? and announcement['publish_at'].to_datetime >= 2.weeks.ago
        mail_logs = API[:notification].rel(:mail_log_stats).get(news_id: announcement['id']).value!
        if announcement['receivers'].present?
          delta = announcement['receivers'] - mail_logs["count"]
          if delta >= allowed_delta and mail_logs["newest"] < 10.minutes.ago
            annotation = 'Announcement failed ' + announcement['title'].to_s + ' (' + announcement['id'].to_s + ')'
            qc_alert_data = create_json(announcement['id'])
            update_or_create_qc_alert_with_data(rule_id, course_id, severity, annotation, announcement['id'], qc_alert_data)
          else
            find_and_close_qc_alert_with_data(rule_id, course_id, announcement['id'])
          end
        end
      else
        find_and_close_qc_alert_with_data(rule_id, course_id, announcement['id'])
      end
    end
  end
end