class AddDescriptionToResearchCases < ActiveRecord::Migration[4.2]
  def change
    add_column :research_cases, :description, :string
  end
end
