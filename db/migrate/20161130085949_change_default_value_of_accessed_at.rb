# frozen_string_literal: true

class ChangeDefaultValueOfAccessedAt < ActiveRecord::Migration[4.2]
  def change
    change_column :datasource_accesses, :accessed_at, :datetime, default: '1970-01-01 00:00:00' # rubocop:disable Rails/ReversibleMigration
  end
end
