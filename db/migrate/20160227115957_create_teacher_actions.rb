# frozen_string_literal: true

class CreateTeacherActions < ActiveRecord::Migration[4.2]
  def change
    create_table :teacher_actions, id: :uuid do |t|
      t.uuid :cluster_group_id
      t.uuid :author_id
      t.uuid :richtext_id
      t.jsonb :subject
      t.jsonb :user_uuids
      t.datetime :action_performed_at
      t.timestamps
    end
  end
end
