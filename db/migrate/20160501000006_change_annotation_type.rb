class ChangeAnnotationType < ActiveRecord::Migration
  def change
    change_column :qc_alerts, :annotation, :text
  end
end

