class CreateResearchCases < ActiveRecord::Migration
  def change
    create_table :research_cases do |t|
      t.string :title

      t.timestamps
    end
  end
end
