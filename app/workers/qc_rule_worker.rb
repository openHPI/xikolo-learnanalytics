class QcRuleWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :high

  def perform(course, rule_id)
  end

  private

  def update_or_create_qc_alert(rule_id, course_id, severity, annotation = '')
    alert = QcAlert.find_by(qc_rule_id: rule_id, course_id: course_id)
    if alert and alert.status == 'open'
      # Alert is open -> update updated at
      alert.updated_at = DateTime.now
      alert.severity = severity
      alert.annotation = annotation
      alert.save
    end
    if alert and alert.status == 'closed'
      alert.updated_at = DateTime.now
      alert.severity = severity
      alert.annotation = annotation
      alert.status = 'open'
      alert.save
    end
    if not alert
      # Alert is closed or non existing -> open Alert
      new_alert = QcAlert.new(qc_rule_id: rule_id, status: 'open', severity: severity, course_id: course_id, annotation: annotation)
      new_alert.save
    end
  end


    def update_or_create_qc_alert_with_data(rule_id, course_id, severity, annotation = '', resource_id, qc_alert_data)
      alert = QcAlert.where(qc_rule_id: rule_id, course_id: course_id).where("(qc_alert_data->>'resource_id')= ?", resource_id).first
      if alert
        if alert.status == 'open'
        # Alert is open -> update updated at
        alert.updated_at = DateTime.now
        alert.severity = severity
        alert.annotation = annotation
        alert.qc_alert_data = qc_alert_data
        alert.save
        elsif alert.status == 'closed'
          alert.updated_at = DateTime.now
          alert.severity = severity
          alert.annotation = annotation
          alert.status = 'open'
          alert.qc_alert_data = qc_alert_data
          alert.save
        end
      else
        # no alert -> open Alert
        new_alert = QcAlert.new(qc_rule_id: rule_id,
            status: 'open',
            severity: severity,
            course_id: course_id,
            annotation: annotation,
            qc_alert_data: qc_alert_data)
        new_alert.save
      end
  end

  def find_and_close_qc_alert (rule_id, course_id)
    alerts = QcAlert.where(qc_rule_id: rule_id, course_id: course_id)
    alerts.each do |alert|
      if alert and alert.status == 'open'
        # Check if Alert is open, if so, close it
        alert.status = 'closed'
        alert.updated_at = DateTime.now
        alert.save
      end
    end
  end


  def find_and_close_qc_alert_with_data(rule_id, course_id, resource_id)
    alerts =  QcAlert.where(qc_rule_id: rule_id, course_id: course_id).where("(qc_alert_data->>'resource_id')= ?", resource_id)
    alerts.each do |alert|
      if alert and alert.status == 'open'
          # Check if Alert is open, if so, close it
          alert.status = 'closed'
          alert.updated_at = DateTime.now
          alert.save
      end
    end
  end

  def course_is_active(course)
    if course.start_date.present? && course.end_date.present?
        course.start_date <=  DateTime.now and course.end_date >= DateTime.now and course.status == 'active'
    end
  end

  def create_json(resource_id)
    {"resource_id" => resource_id}
  end
end