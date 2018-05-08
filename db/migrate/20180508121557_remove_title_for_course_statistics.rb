class RemoveTitleForCourseStatistics < ActiveRecord::Migration
  def change
    remove_column :course_statistics, :course_name
  end
end
