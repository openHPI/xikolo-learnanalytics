class AddAnnotationToQcAlert < ActiveRecord::Migration
  def change
    change_table :qc_alerts do |t|
      t.string :annotation
    end
  end
end
