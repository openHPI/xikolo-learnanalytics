class QcAlert < ApplicationRecord
  has_many :qc_alert_statuses
  has_many :qc_course_statuses
  belongs_to :qc_rule
  default_scope { order updated_at: :desc }

  def close!
    update(status: 'closed')
  end
end