class JobsController < ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  # List allowed filter parameters for #index here.
  rfc6570_params index: [:job_params, :task_type, :user_id, :show_expired]

  def index
    jobs = Job.all
    jobs.where! id: params[:id] if params[:id]
    jobs.where! user_id: params[:user_id] if params[:user_id]
    jobs.where! task_type: params[:task_type] if params[:task_type]
    if params[:show_expired].blank? or !params[:show_expired]
      jobs.where!("file_expire_date >= ? OR file_expire_date IS NULL", DateTime.now())
      jobs.where!(
          "status = 'failed' and created_at >= '#{(Time.now - 5.days).utc.iso8601}' " + \
          "OR updated_at >= '#{(Time.now - 3.days).utc.iso8601}'"
      )
    end

    respond_with jobs
  end

  def show
    respond_with Job.find params[:id]
  end

  def create
    job = Job.create job_params.merge({status: 'requested'})
    job.schedule report_params if job.valid?

    respond_with job
  end

  def update
    respond_with Job.find(params[:id]).update_attributes(job_params)
  end

  private

  def job_params
    params.permit(:task_type, :task_scope, :job_params, :created_by, :file_id, :file_expire_date, :user_id)
  end

  def report_params
    params.permit(:zip_password, :privacy_flag, :extended_flag, :combined_enrollment_info_flag, :include_all_quizzes)
  end
end