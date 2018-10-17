class QcAlertStatusesController < ApplicationController
  responders Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  def index
    respond_with QcAlertStatus.all
  end

  def show
    respond_with QcAlertStatus.find params[:id]
  end

  def create
    qc_alert_status = QcAlertStatus.create qc_alert_statuses_params
    qc_alert_status.save
    if params[:user_id] && params[:qc_alert_id]
      qc_alert_status.qc_alert_id =  params[:qc_alert_id] if params[:qc_alert_id]
      qc_alert_status.user_id=  params[:user_id] if params[:user_id]
      qc_alert_status.ignored = params[:ignored] if params[:ignored]
      qc_alert_status.muted = params[:muted] if params[:muted]
      qc_alert_status.course_id = params[:course_id] if params[:course_id]
      qc_alert_status.save
    end
    respond_with qc_alert_status
  end

  private

  def qc_alert_statuses_params
    params.permit( :qc_alert_id, :user_id, :ignored, :ack, :muted)
  end

end