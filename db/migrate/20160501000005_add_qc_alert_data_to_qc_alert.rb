class AddQcAlertDataToQcAlert < ActiveRecord::Migration
    def change
      change_table :qc_alerts do |t|
        t.text :qc_alert_data
      end
    end
end
