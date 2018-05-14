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
    respond_with CourseStatistic.find_by! course_id: params[:id]
  end

  def decorate(res)
    return res.map{ |item| decorate item } if res.kind_of?(Array)
    return res.decorate if res.respond_to? :decorate
    res
  end
end
