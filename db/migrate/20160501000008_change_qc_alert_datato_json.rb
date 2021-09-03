# frozen_string_literal: true

class ChangeQcAlertDatatoJson < ActiveRecord::Migration[4.2]
  def change
    change_column :qc_alerts, :qc_alert_data, 'json USING CAST(qc_alert_data as JSON)'
  end
end
