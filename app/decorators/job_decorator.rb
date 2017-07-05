class JobDecorator < ApplicationDecorator
  delegate_all

  def as_json (**opts)
    { id: model.id,
      task_type: model.task_type,
      task_scope: model.task_scope,
      status: model.status,
      job_params: model.job_params,
      file_id: model.file_id,
      file_expire_date: model.file_expire_date,
      user_id: model.user_id,
      progress: model.progress,
      annotation: model.annotation
    }.tap { |fields|
      fields[:error_text] = model.error_text if job.failing?
    }.as_json(**opts)
  end
end