# frozen_string_literal: true

class QcAlertStatus < ApplicationRecord
  belongs_to :qc_alert, optional: true
end
