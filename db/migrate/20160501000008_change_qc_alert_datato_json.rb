class ChangeQcAlertDatatoJson < ActiveRecord::Migration
  def change
    change_column :qc_alerts, :qc_alert_data, 'json USING CAST(qc_alert_data as JSON)'
  end
end