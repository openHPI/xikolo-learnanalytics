# frozen_string_literal: true

class CreateSectionConversions < ActiveRecord::Migration[5.2]
  def change
    create_table :section_conversions, id: :uuid do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.uuid :course_id
      t.jsonb :data
    end
  end
end
