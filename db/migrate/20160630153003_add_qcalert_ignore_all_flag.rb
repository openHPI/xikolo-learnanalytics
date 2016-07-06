class AddQcalertIgnoreAllFlag < ActiveRecord::Migration
  def change
    change_table :qc_alerts do |t|
      t.boolean :is_global_ignored, null: false, default: false
    end
  end
end
