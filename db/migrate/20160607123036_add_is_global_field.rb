class AddIsGlobalField < ActiveRecord::Migration[4.2]
  def change
    change_table :qc_rules do |t|
      t.boolean :is_global
    end
  end
end
