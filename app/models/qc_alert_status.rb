class QcAlertStatus < ApplicationRecord
  belongs_to :qc_alert, optional: true
end