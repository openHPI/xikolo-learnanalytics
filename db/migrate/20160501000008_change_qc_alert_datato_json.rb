# frozen_string_literal: true

class ChangeQcAlertDatatoJson < ActiveRecord::Migration[4.2]
  def up
    change_column :qc_alerts, :qc_alert_data, 'json USING CAST(qc_alert_data AS JSON)'
  end

  def down
    change_column :qc_alerts, :qc_alert_data, :text
  end
end
