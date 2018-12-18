class RevertPreviousMigration < ActiveRecord::Migration[5.2]
  def change
    rename_column :course_statistics, :roa_count, :certificates
    remove_column :course_statistics, :cop_count, :integer
    remove_column :course_statistics, :qc_count, :integer
    remove_column :course_statistics, :consumption_rate, :float
  end
end
