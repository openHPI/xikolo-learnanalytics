# frozen_string_literal: true

class ReportJobDecorator < ApplicationDecorator
  delegate_all

  def as_json(opts = {})
    {
      id: model.id,
      task_type: model.task_type,
      task_scope: model.task_scope,
      status: model.status,
      job_params: model.job_params,
      download_url: model.download_url,
      file_expire_date: model.file_expire_date,
      user_id: model.user_id,
      options: model.options,
      progress: model.progress,
      annotation: model.annotation,
    }.tap do |fields|
      fields[:error_text] = model.error_text if report_job.failing?
    end.as_json(opts)
  end
end
