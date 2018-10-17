class QcCourseStatusesController< ApplicationController
  responders Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  def index
    respond_with QcCourseStatus.all
  end

  def show
    respond_with QcCourseStatus.find params[:id]
  end

  def create
    qc_course_status = QcCourseStatus.create qc_course_status_params
    qc_course_status.save
    respond_with qc_course_status
  end

  private

  def qc_course_status_params
    params.permit( :qc_rule_id, :course_id, :status)
  end
end