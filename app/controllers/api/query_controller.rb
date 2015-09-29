class Api::QueryController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO: secure controller when researcher interface is published
  skip_before_action :require_login, only: [:show]

  rfc6570_params show: [:metric, :user_id, :course_id, :start_time, :end_time]
  def show
    if metric.nil?
      metric_error
      return
    end
    render json: metric.query(query_params[:user_id],
                              query_params[:course_id],
                              query_params[:start_time],
                              query_params[:end_time])
  end

  private

  def metric
    return unless metric_names.include? params[:metric]

    "Lanalytics::Metric::#{params[:metric]}".constantize
  end

  def metric_names
    %w(PinboardActivity PinboardPostingActivity PinboardWatchCount
       VideoVisitCount VisitCount QuestionResponseTime VideoSpeedChangeMetric
       CourseActivity CourseActivityTimebased CoursePoints VideoPlayerAdvancedCount)
  end

  def query_params
    params.permit :user_id, :course_id, :start_time, :end_time
  end

  def metric_error
    render json: {
      error: {
        metric: "must be one of #{metric_names.join(', ')}"
      }
    }, status: 422
  end
end
