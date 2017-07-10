class CourseStatisticsController < ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder
  respond_to :json

  def index
    course_statistics = []
    if params[:historic_data] == 'true'
      if params[:start_date] and params[:course_id]
        course_statistics = CourseStatistic.versions_for(
          params[:course_id],
          params[:start_date],
          params[:end_date]
        )
      end
    else
      course_statistics = CourseStatistic.all
    end
    respond_with course_statistics
  end

  def show
    # incoming id is a course_id!
    respond_with CourseStatistic.retrieve params[:id]
  end
end
