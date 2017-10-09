module QcRules
  class AnnouncementFailed
    def initialize(rule)
      @rule = rule
    end

    def run
      Xikolo.paginate(
        Xikolo.api(:news).value!.rel(:news_index).get(
          published: true
        )
      ) do |announcement|
        if announcement['publish_at'].blank? or announcement['publish_at'].to_datetime < 2.weeks.ago
          alerts_for(announcement).close!
          next
        end

        mail_logs = notification_service.rel(:mail_log_stats).get(news_id: announcement['id']).value!
        next if announcement['receivers'].blank?

        if announcement_failed?(announcement, mail_logs)
          alerts_for(announcement).open!(
            severity: 'high',
            annotation: "Announcement failed #{announcement['title']} (#{announcement['id']})"
          )
        else
          alerts_for(announcement).close!
        end
      end
    end

    private

    def alerts_for(announcement)
      @rule.alerts_for(
        course_id: announcement['course_id'] # may be nil
      ).with_data(
        resource_id: announcement['id']
      )
    end

    def announcement_failed?(announcement, mail_logs)
      delta = announcement['receivers'] - mail_logs['count']
      delta >= 10 and mail_logs['newest'] < 10.minutes.ago
    end

    def news_service
      @news_service ||= Xikolo.api(:news).value!
    end

    def notification_service
      @notification_service ||= Xikolo.api(:notification).value!
    end
  end
end
