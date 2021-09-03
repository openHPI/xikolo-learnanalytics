# frozen_string_literal: true

class RevertPreviousMigration < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/BulkChangeTable
  def change
    rename_column :course_statistics, :roa_count, :certificates
    remove_column :course_statistics, :cop_count, :integer
    remove_column :course_statistics, :qc_count, :integer
    remove_column :course_statistics, :consumption_rate, :float
  end
  # rubocop:enable all
end
