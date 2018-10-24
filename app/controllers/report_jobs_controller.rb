class ReportJobsController < ApplicationController
  responders Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  # List allowed filter parameters for #index here.
  rfc6570_params index: [:job_params, :task_type, :user_id, :show_expired]

  def index
    jobs = ReportJob.all
    jobs.where! id: params[:id] if params[:id]
    jobs.where! user_id: params[:user_id] if params[:user_id]
    jobs.where! task_type: params[:task_type] if params[:task_type]
    if params[:show_expired].blank? or !params[:show_expired]
      jobs.where!("file_expire_date >= ? OR file_expire_date IS NULL", DateTime.now)
      jobs.where!(
          "status = 'failed' and created_at >= '#{(Time.now - 5.days).utc.iso8601}' " + \
          "OR updated_at >= '#{(Time.now - 3.days).utc.iso8601}'"
      )
    end

    respond_with jobs
  end

  def show
    respond_with ReportJob.find params[:id]
  end

  def create
    job = ReportJob.create job_params.merge({status: 'requested'})
    job.schedule options if job.valid?

    respond_with job
  end

  def update
    respond_with ReportJob.find(params[:id]).update_attributes(job_params)
  end

  def destroy
    job = ReportJob.find(params[:id])
    respond_with job.destroy
  rescue ReportJob::ReportJobRunningError => e
    render json: { error: e.message }, status: :conflict
  end

  private

  def job_params
    params.permit(:task_type, :task_scope, :job_params, :user_id)
  end

  def options
    params['options'].is_a?(ActionController::Parameters) ? params['options'].to_unsafe_h : {}
  end
end
