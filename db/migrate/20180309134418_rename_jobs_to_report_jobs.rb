class RenameJobsToReportJobs < ActiveRecord::Migration
  def change
    rename_table :jobs, :report_jobs
  end
end
