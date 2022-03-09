# frozen_string_literal: true

class RemoveSectionConversions < ActiveRecord::Migration[6.1]
  def up
    drop_table :section_conversions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
