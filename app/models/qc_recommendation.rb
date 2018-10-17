class QcRecommendation < ApplicationRecord
  has_one :qc_alert
  has_one :qc_rule_id
  default_scope { order updated_at: :desc }
end