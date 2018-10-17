class ChangeAnnotationType < ActiveRecord::Migration[4.2]
  def change
    change_column :qc_alerts, :annotation, :text
  end
end

