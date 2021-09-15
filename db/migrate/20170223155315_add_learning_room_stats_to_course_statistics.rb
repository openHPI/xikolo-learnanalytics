# frozen_string_literal: true

class AddLearningRoomStatsToCourseStatistics < ActiveRecord::Migration[4.2]
  # rubocop:disable Rails/BulkChangeTable
  def change
    add_column :course_statistics, :learning_rooms_threads, :integer
    add_column :course_statistics, :learning_rooms_threads_last_day, :integer
  end
  # rubocop:enable all
end
