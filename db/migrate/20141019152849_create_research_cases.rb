# frozen_string_literal: true

class CreateResearchCases < ActiveRecord::Migration[4.2]
  def change
    create_table :research_cases do |t|
      t.string :title

      t.timestamps
    end
  end
end
