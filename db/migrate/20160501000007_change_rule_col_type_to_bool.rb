# frozen_string_literal: true

class ChangeRuleColTypeToBool < ActiveRecord::Migration[4.2]
  # rubocop:disable Rails/BulkChangeTable
  # rubocop:disable Rails/ReversibleMigration
  def change
    remove_column :qc_rules, :status
    add_column :qc_rules, :is_active, :boolean
  end
  # rubocop:enable all
end
