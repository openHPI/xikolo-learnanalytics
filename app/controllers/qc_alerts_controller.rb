class QcAlertsController < ApplicationController
  responders Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  rfc6570_params index: [:user_id, :course_id, :global_ignored]
  def index
    alerts = QcAlert.all
    alerts = alerts.where(course_id: params[:course_id]) if params[:course_id]
    alerts = alerts.where(is_global_ignored: [false, nil]) unless params[:global_ignored]
    alerts = alerts.for_user(params[:user_id]) if params[:user_id]

    respond_with alerts
  end

  def show
    respond_with QcAlert.find params[:id]
  end

  def ignore
    if params[:qc_alert_id]
      qc_alert_status = QcAlertStatus.create qc_alert_statuses_params.merge({ignored: true})
      qc_alert_status.save
      respond_with qc_alert_status

    elsif params[:qc_rule_id] && params[:course_id]
      qc_course_status = QcCourseStatus.create qc_course_statuses_params.merge({status: 'ignored'})
      qc_course_status.save
      respond_with qc_course_status
    end
  end

  def create
    qc_alert = QcAlert.create qc_alert_params
    qc_alert.save
    respond_with qc_alert
  end

  def update
    q = QcAlert.find(params[:id])
    q.update_attributes(qc_alert_params)
    respond_with q
  end

private

  def qc_alert_params
    params.permit(:qc_rule_id, :status, :severity, :course_id, :annotation, :is_global_ignored)
  end

  def qc_alert_statuses_params
    params.permit(:qc_alert_id, :user_id, :ignored, :ack, :muted)
  end

  def qc_course_statuses_params
    params.permit(:qc_rule_id, :course_id, :status)
  end
end
