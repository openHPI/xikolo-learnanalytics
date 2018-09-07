class RemoveFileIdFromReportJobs < ActiveRecord::Migration
  def change
    remove_column :report_jobs, :file_id, :uuid
  end
end
