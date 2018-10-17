class AddQcAlertDataToQcAlert < ActiveRecord::Migration[4.2]
    def change
      change_table :qc_alerts do |t|
        t.text :qc_alert_data
      end
    end
end
