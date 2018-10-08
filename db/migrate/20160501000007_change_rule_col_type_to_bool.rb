class ChangeRuleColTypeToBool < ActiveRecord::Migration[4.2]
  def change
    remove_column  :qc_rules, :status
    add_column :qc_rules, :is_active, :boolean
  end
end
