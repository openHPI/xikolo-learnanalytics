# frozen_string_literal: true

class AddAnnotationCode < ActiveRecord::Migration[4.2]
  def change
    change_table :jobs do |t|
      t.string :annotation
    end
  end
end
