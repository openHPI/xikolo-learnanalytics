class AddCourseStatistics < ActiveRecord::Migration
  def change
    create_table :course_statistics, id: :uuid do |t|
      t.string :course_name
      t.string :course_code
      t.string :course_status
      t.uuid :course_id
      t.integer :total_enrollments
      t.float :no_shows
      t.integer :current_enrollments
      t.integer :enrollments_last_24h
      t.integer :enrollments_at_course
      t.integer :enrollments_at_course_middle_incl_unenrollments
      t.integer :enrollments_at_course_middle
      t.integer :enrollments_at_course_end
      t.integer :total_questions
      t.integer :questions_last_24h
      t.integer :total_answers
      t.integer :answers_last_24h
      t.integer :total_comments_on_answers
      t.integer :comments_on_answers_last_24h
      t.integer :total_comments_on_questions
      t.integer :comments_on_questions_last_24h
      t.integer :certificates
      t.integer :helpdesk_tickets
      t.integer :helpdesk_tickets_last_24h
      t.float :completion_rate
      t.float :consumption_rate
      t.datetime :start_date
      t.datetime :end_date
      t.integer :new_users
      t.timestamps
    end
  end
end
