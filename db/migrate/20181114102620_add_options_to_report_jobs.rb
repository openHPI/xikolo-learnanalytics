# frozen_string_literal: true

class AddOptionsToReportJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :report_jobs, :options, :jsonb, default: {}, null: false
  end
end
