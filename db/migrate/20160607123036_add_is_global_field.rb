class AddIsGlobalField < ActiveRecord::Migration
  def change
    change_table :qc_rules do |t|
      t.boolean :is_global
    end
  end
end
