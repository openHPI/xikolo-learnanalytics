# frozen_string_literal: true

class AddIndexOnEventsCourseId < ActiveRecord::Migration[4.2]
  def up
    execute "CREATE INDEX events_in_context_course_id ON events ((in_context->>'course_id'));"
  end

  def down
    execute 'DROP INDEX events_in_context_course_id;'
  end
end
