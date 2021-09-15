# frozen_string_literal: true

class RebuildClusterGroups < ActiveRecord::Migration[4.2]
  def change
    drop_table :cluster_groups if ActiveRecord::Base.connection.table_exists? 'cluster_groups' # rubocop:disable Rails/ReversibleMigration

    create_table :cluster_groups, id: :uuid do |t|
      t.string :name
      t.jsonb :user_uuids
      t.jsonb :cluster_results
      t.uuid :course_id
      t.timestamps
    end
  end
end
