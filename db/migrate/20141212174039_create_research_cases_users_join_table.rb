# frozen_string_literal: true

class CreateResearchCasesUsersJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_table :research_cases_users, id: false do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.integer :research_case_id
      t.integer :user_id
    end

    add_index :research_cases_users, %i[research_case_id user_id]
  end
end
