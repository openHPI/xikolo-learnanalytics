class RemoveFileIdFromReportJobs < ActiveRecord::Migration[4.2]
  def change
    remove_column :report_jobs, :file_id, :uuid
  end
end
