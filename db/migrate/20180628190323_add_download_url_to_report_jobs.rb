# frozen_string_literal: true

class AddDownloadUrlToReportJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :report_jobs, :download_url, :string
  end
end
