# frozen_string_literal: true

class AddNativePostgresDatasource < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.string :user_uuid
      t.integer :verb_id
      t.integer :resource_id
      t.jsonb :in_context
      t.jsonb :with_result
      t.timestamps
    end

    create_table :verbs do |t|
      t.string :verb
      t.timestamps
    end

    create_table :resources do |t|
      t.string :uuid
      t.string :resource_type # can't call the column 'type', because that's a special keyword
      t.timestamps
    end
  end
end
