class QcRecommendationDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    { id: model.id,
      qc_alert_id: model.qc_alert_id,
    }.as_json(opts)
  end
end