# frozen_string_literal: true

class ChangeObjectFieldToJson < ActiveRecord::Migration[4.2]
  # rubocop:disable Rails/BulkChangeTable
  # rubocop:disable Rails/ReversibleMigration
  def change
    remove_column :versions, :object
    add_column :versions, :object, :json
  end
  # rubocop:enable all
end
