class QcCourseStatusesController< ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json
  rfc6570_params index: [ :course_id, :qc_rule_id]

  def index
    course_statuses = QcCourseStatus.all
    if params['offset'].nil?
      @offset = 0
    elsif
    @offset = params['offset']
    end

    respond_with course_statuses.offset(@offset)
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