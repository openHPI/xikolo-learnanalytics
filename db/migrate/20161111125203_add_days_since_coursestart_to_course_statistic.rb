class AddDaysSinceCoursestartToCourseStatistic < ActiveRecord::Migration
  def change
    add_column :course_statistics, :days_since_coursestart, :integer
  end
end
