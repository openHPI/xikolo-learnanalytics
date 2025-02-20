# frozen_string_literal: true

class ChangeAnnotationType < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up { change_column :qc_alerts, :annotation, :text }
      dir.down { change_column :qc_alerts, :annotation, :string }
    end
  end
end
