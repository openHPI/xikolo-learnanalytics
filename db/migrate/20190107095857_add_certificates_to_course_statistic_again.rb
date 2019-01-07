class AddCertificatesToCourseStatisticAgain < ActiveRecord::Migration[5.2]
  def change
    rename_column :course_statistics, :certificates, :roa_count
    add_column :course_statistics, :cop_count, :integer
    add_column :course_statistics, :qc_count, :integer
    add_column :course_statistics, :consumption_rate, :float
  end
end
