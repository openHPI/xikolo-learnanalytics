# frozen_string_literal: true

class AddCourseStatistics < ActiveRecord::Migration[4.2]
  def change
    create_table :course_statistics, id: :uuid do |t|
      t.string :course_name
      t.string :course_code
      t.string :course_status
      t.uuid :course_id
      t.integer :total_enrollments
      t.float :no_shows
      t.integer :current_enrollments
      t.integer :enrollments_last_day
      t.integer :enrollments_at_course_start
      t.integer :enrollments_at_course_middle_netto
      t.integer :enrollments_at_course_middle
      t.integer :enrollments_at_course_end
      t.integer :total_questions
      t.integer :questions_last_day
      t.integer :total_answers
      t.integer :answers_last_day
      t.integer :total_comments_on_answers
      t.integer :comments_on_answers_last_day
      t.integer :total_comments_on_questions
      t.integer :comments_on_questions_last_day
      t.integer :certificates
      t.integer :helpdesk_tickets
      t.integer :helpdesk_tickets_last_day
      t.float :completion_rate
      t.float :consumption_rate
      t.datetime :start_date
      t.datetime :end_date
      t.integer :new_users
      t.json :enrollments_per_day
      t.boolean :hidden
      t.timestamps
    end
  end
end
