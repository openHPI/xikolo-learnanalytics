class AddErrorTextToJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :jobs, :error_text, :text
  end
end
