class AddErrorTextToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :error_text, :text
  end
end
