class QcAlertStatusDecorator< ApplicationDecorator
  delegate_all

  def as_json (**opts)
    { id: model.id,
      qc_alert_id: model.qc_alert_id,
      user_id: model.user_id,
      ignored: model.ignored,
      muted: model.muted,
      ack: model.ack,
    }.as_json(**opts)
  end
end