class RemoveTitleForCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    remove_column :course_statistics, :course_name
  end
end
