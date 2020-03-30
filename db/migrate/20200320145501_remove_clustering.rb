# frozen_string_literal: true

class RemoveClustering < ActiveRecord::Migration[5.2]
  def up
    drop_table :cluster_groups
    drop_table :datasource_accesses
    drop_table :datasources
    drop_table :research_cases
    drop_table :research_cases_users
    drop_table :teacher_actions
    drop_table :users
  end
end
