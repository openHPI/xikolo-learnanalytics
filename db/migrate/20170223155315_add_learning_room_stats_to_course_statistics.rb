class AddLearningRoomStatsToCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    add_column :course_statistics, :learning_rooms_threads, :integer
    add_column :course_statistics, :learning_rooms_threads_last_day, :integer
  end
end
