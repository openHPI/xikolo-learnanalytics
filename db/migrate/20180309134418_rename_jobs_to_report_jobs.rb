# frozen_string_literal: true

class RenameJobsToReportJobs < ActiveRecord::Migration[4.2]
  def change
    rename_table :jobs, :report_jobs
  end
end
