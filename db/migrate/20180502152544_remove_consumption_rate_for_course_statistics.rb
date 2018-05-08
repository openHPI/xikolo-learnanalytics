class RemoveConsumptionRateForCourseStatistics < ActiveRecord::Migration
  def change
    remove_column :course_statistics, :consumption_rate
  end
end
