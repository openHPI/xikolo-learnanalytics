class QcAlertsController < ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  rfc6570_params index: [:user_id, :course_id, :offset]
  def index
    alerts = QcAlert.joins('LEFT OUTER JOIN qc_alert_statuses ON qc_alerts.id = qc_alert_statuses.qc_alert_id')
    alerts.where!('qc_alert_statuses.ignored is FALSE OR qc_alert_statuses.ignored is NULL')

    alerts.where!('qc_alert_statuses.user_id = ?', params[:user_id]) if params[:user_id]

    alerts.where!('qc_alerts.course_id = ?', params[:course_id]) if params[:course_id]

    alerts.offset!(params['offset']) if params['offset']

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
      qc_course_status = QcCourseStatus.create qc_course_status_params.merge({status: 'ignored'})
      qc_course_status.save
      respond_with qc_course_status
    end
  end

  def create
    qc_alert = QcAlert.create qc_alert_params
    qc_alert.save
    respond_with qc_alert
  end

private

  def qc_alert_params
    params.permit( :qc_rule_id, :status, :severity, :course_id, :annotation)
  end

  def qc_alert_statuses_params
    params.permit( :qc_alert_id, :user_id, :ignored, :ack, :muted)
  end

  def qc_course_status_params
    params.permit( :qc_rule_id, :course_id, :status)
  end
end