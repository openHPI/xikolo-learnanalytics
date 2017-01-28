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
    unless params[:show_expired].present? and params[:show_expired] == true
      jobs.where!("file_expire_date >= ? OR file_expire_date IS NULL", DateTime.now())
      jobs.where!(
          "status = 'failed' and created_at >= '#{(Time.now - 5.days).utc.iso8601}' " + \
          "OR updated_at >= '#{(Time.now - 3.days).utc.iso8601}'"
      )
    end
    if params['offset'].nil?
      @offset = 0
    elsif
      @offset = params['offset']
    end
    respond_with jobs.offset(@offset)

  end

  def show
    respond_with Job.find params[:id]
  end

  def create
    job = Job.create job_params.merge({status: 'requested'})
    case params[:task_type]
      when 'course_export'
        if params[:task_scope] && params[:user_id]
          CreateCourseExportJob.perform_later(job.id, params[:zip_password], params[:user_id], params[:task_scope], params[:privacy_flag], params[:extended_flag] )
        end
      when 'user_info_export'
        if params[:user_id]
          CreateUserInfoExportJob.perform_later(job.id, params[:zip_password], params[:user_id], params[:task_scope] , params[:privacy_flag], params[:combined_enrollment_info_flag] )
        end
      when 'submission_export'
        if params[:task_scope] && params[:user_id]
          CreateSubmissionExportJob.perform_later(job.id, params[:zip_password], params[:user_id], params[:task_scope] , params[:privacy_flag] )
        end
      when 'pinboard_export'
        if params[:task_scope] && params[:user_id]
          CreatePinboardExportJob.perform_later(job.id, params[:zip_password], params[:user_id], params[:task_scope], params[:privacy_flag])
        end
      when 'metric_export'
        if params[:task_scope] && params[:user_id]
          CreateMetricExportJob.perform_later(job.id, params[:zip_password], params[:user_id], params[:task_scope], params[:privacy_flag])
        end
      when 'course_events_export'
        if params[:task_scope] && params[:user_id]
          CreateCourseEventsExportJob.perform_later(job.id, params[:zip_password], params[:user_id], params[:task_scope], params[:privacy_flag])
        end
      when 'combined_course_export'
        if params[:task_scope] && params[:user_id]
          CreateCombinedCourseExportJob.perform_later(job.id, params[:zip_password], params[:user_id], params[:task_scope], params[:privacy_flag], params[:extended_flag] )
        end
    end
    respond_with job
  end

  def update
    respond_with Job.find(params[:id]).update_attributes(job_params)
  end

  private

  def job_params
    params.permit( :task_type, :task_scope, :job_params, :created_by, :file_id, :file_expire_date, :user_id )
  end
end