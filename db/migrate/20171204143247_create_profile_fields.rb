# frozen_string_literal: true

class CreateProfileFields < ActiveRecord::Migration[4.2]
  def change
    create_table :profile_fields do |t|
      t.string :name, null: false
      t.boolean :sensitive, default: false, null: false
      t.boolean :omittable, default: false, null: false

      t.timestamps null: false
    end
  end
end
