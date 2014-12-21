class AddDescriptionToResearchCases < ActiveRecord::Migration
  def change
    add_column :research_cases, :description, :string
  end
end
