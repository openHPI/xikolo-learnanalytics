class AddAnnotationToQcAlert < ActiveRecord::Migration[4.2]
  def change
    change_table :qc_alerts do |t|
      t.string :annotation
    end
  end
end
