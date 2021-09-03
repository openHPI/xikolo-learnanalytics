# frozen_string_literal: true

class QcRecommendation < ApplicationRecord
  has_one :qc_alert, dependent: :destroy

  default_scope { order updated_at: :desc }
end
