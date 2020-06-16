# frozen_string_literal: true

class AddTimestampsToSectionConversions < ActiveRecord::Migration[5.2]
  def change
    change_table :section_conversions, bulk: true do |t|
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
