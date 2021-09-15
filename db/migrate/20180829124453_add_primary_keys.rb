# frozen_string_literal: true

class AddPrimaryKeys < ActiveRecord::Migration[4.2]
  def up
    execute 'ALTER TABLE research_cases_users ADD PRIMARY KEY (research_case_id, user_id);'
    remove_index :research_cases_users, name: :index_research_cases_users_on_research_case_id_and_user_id
    execute 'ALTER TABLE datasources ADD CONSTRAINT datasources_pkey PRIMARY KEY USING INDEX index_datasources_on_key;'
  end

  def down
    execute 'ALTER TABLE research_cases_users DROP CONSTRAINT research_cases_users_pkey;'
    add_index :research_cases_users, %i[research_case_id user_id]
    execute 'ALTER TABLE datasources DROP CONSTRAINT datasources_pkey;'
    add_index :datasources, :key, unique: true
  end
end
