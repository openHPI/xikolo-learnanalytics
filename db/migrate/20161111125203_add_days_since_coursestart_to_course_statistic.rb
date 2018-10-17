class AddDaysSinceCoursestartToCourseStatistic < ActiveRecord::Migration[4.2]
  def change
    add_column :course_statistics, :days_since_coursestart, :integer
  end
end
