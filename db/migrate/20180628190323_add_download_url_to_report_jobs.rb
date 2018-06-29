class AddDownloadUrlToReportJobs < ActiveRecord::Migration
  def change
    add_column :report_jobs, :download_url, :string
  end
end
