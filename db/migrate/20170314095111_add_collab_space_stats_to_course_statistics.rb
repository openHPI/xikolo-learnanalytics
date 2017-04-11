class AddCollabSpaceStatsToCourseStatistics < ActiveRecord::Migration
  def change
    rename_column :course_statistics, :total_questions, :questions
    rename_column :course_statistics, :total_answers, :answers
    rename_column :course_statistics, :total_comments_on_answers, :comments_on_answers
    rename_column :course_statistics, :total_comments_on_questions, :comments_on_questions
    rename_column :course_statistics, :learning_rooms_threads, :questions_in_learning_rooms
    rename_column :course_statistics, :learning_rooms_threads_last_day, :questions_last_day_in_learning_rooms
    add_column :course_statistics, :answers_in_learning_rooms, :integer
    add_column :course_statistics, :answers_last_day_in_learning_rooms, :integer
    add_column :course_statistics, :comments_on_answers_in_learning_rooms, :integer
    add_column :course_statistics, :comments_on_answers_last_day_in_learning_rooms, :integer
    add_column :course_statistics, :comments_on_questions_in_learning_rooms, :integer
    add_column :course_statistics, :comments_on_questions_last_day_in_learning_rooms, :integer
  end
end
