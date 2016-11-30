class ChangeDefaultValueOfAccessedAt < ActiveRecord::Migration
  def change
    change_column :datasource_accesses, :accessed_at, :datetime, :default => '1970-01-01 00:00:00'
  end
end
