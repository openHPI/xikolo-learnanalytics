class QcAlertDecorator< ApplicationDecorator
  delegate_all

  def as_json (**opts)
    { id: model.id,
      qc_rule_id: model.qc_rule_id,
      worker_name: model.qc_rule.present? ? model.qc_rule.worker : nil, # @deprecated
      rule_name: model.qc_rule.present? ? model.qc_rule.name : nil,
      severity: model.severity,
      status: model.status,
      course_id: model.course_id,
      updated_at: model.updated_at,
      created_at: model.created_at,
      annotation: model.annotation,
      qc_alert_data: model.qc_alert_data,
      is_global_ignored: model.is_global_ignored
    }.as_json(**opts)
  end
end