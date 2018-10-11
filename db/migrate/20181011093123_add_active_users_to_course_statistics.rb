class AddActiveUsersToCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    add_column :course_statistics, :active_users_last_day, :integer, default: 0
    add_column :course_statistics, :active_users_last_7days, :integer, default: 0
  end
end
