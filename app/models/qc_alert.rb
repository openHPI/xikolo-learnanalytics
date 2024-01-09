# frozen_string_literal: true

class QcAlert < ApplicationRecord
  has_many :qc_alert_statuses, dependent: :destroy
  has_many :qc_recommendations, dependent: :destroy
  belongs_to :qc_rule, optional: true

  default_scope { order updated_at: :desc }

  scope :for_user, lambda {|user_id|
    alerts_table = QcAlert.arel_table
    statuses_table = QcAlertStatus.arel_table

    where(alerts_table[:id].not_in(
      statuses_table
        .where(statuses_table[:user_id].eq(user_id))
        .where(statuses_table[:ignored].eq(true))
        .project(:qc_alert_id),
    ))
  }

  def close!
    update(status: 'closed')
  end
end
