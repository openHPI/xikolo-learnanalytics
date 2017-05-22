class QueryController < ApplicationController
  #protect_from_forgery with: :null_session

  # TODO: secure controller
  skip_before_action :require_login

  rfc6570_params show: [:metric, :user_id, :course_id, :start_time, :end_time, :resource_id]

  # course_id may be used as resource id as well depending on the query
  def show
    if metric.nil?
      metric_error
      return
    end

    render json: metric.query(
      query_params[:user_id],
      query_params[:course_id],
      query_params[:start_time],
      query_params[:end_time],
      query_params[:resource_id],
      query_params[:page], # only used for lists
      query_params[:per_page] # only used for lists
    )
  end

  def clustering_job
    job_id = SecureRandom.uuid

    ClusterWorker.perform_async(
      job_id,
      cluster_params[:num_centers],
      cluster_params[:course_id],
      cluster_params[:dimensions].sort
    )

    render json: {
      job_id: job_id
    }
  end

  def job_results
    render json: Rails.cache.fetch(params[:job_id])
  end

  def available_cluster_dimensions
    verbs   = Lanalytics::Clustering::Dimensions::ALLOWED_VERBS
    metrics = Lanalytics::Clustering::Dimensions::ALLOWED_METRICS

    render json: (verbs + metrics).sort
  end

  private

  def metric
    return unless metric_names.include? params[:metric]

    "Lanalytics::Metric::#{params[:metric]}".constantize
  end

  def metric_names
    %w(PinboardActivity PinboardPostingActivity PinboardWatchCount
       UnenrollmentCount VideoVisitCount VisitCount QuestionResponseTime
       VideoSpeedChangeMetric CourseActivity CourseActivityTimebased
       CoursePoints VideoPlayerAdvancedCount GeoActivity VideoEvents
       ActiveUserCount CourseActivityList UserActivityCount CourseEvents
       ItemVisits QuizPerformance TopCountries UserCourseCountry Sessions
       AvgSessionDuration TotalSessionDuration ReferrerCount DeviceUsage
       ForumActivity ForumTextualContribution ForumObservation
       ItemDiscovery VideoDiscovery QuizDiscovery
       VideoPlayerActivity DownloadActivity CoursePerformance
       QuizPerformance UngradedQuizPerformance GradedQuizPerformance
       MainQuizPerformance BonusQuizPerformance ShareButtonClicks DeviceUsageCount
       ExternalLinks ActiveUserCountRelative)
  end

  def query_params
    params.permit :user_id, :course_id, :start_time, :end_time, :resource_id, :page
  end

  def cluster_params
    params.permit :num_centers, :course_id, dimensions: []
  end

  def metric_error
    render json: {
      error: {
        metric: "must be one of #{metric_names.join(', ')}"
      }
    }, status: 422
  end

  def protect_from_forgery
  end
end
