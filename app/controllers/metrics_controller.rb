require_dependency 'lanalytics/metric/base'

class MetricsController < ApplicationController

  def show
    name = params[:name]

    if Lanalytics::Metric.resolve(name).nil?
      metric_not_found_error
      return
    end

    render json: Lanalytics::Metric.resolve(name).query(metric_params)
  end

  def index
    render(json: Lanalytics::Metric.all.map { |name|
      {
        name: name.underscore,
        description: Lanalytics::Metric.resolve(name).desc,
        required_params: Lanalytics::Metric.resolve(name).required_params,
        optional_params: Lanalytics::Metric.resolve(name).optional_params
      }
    })
  end

  private

  def metric_params
    params.except(:format, :controller, :action, :name).symbolize_keys
  end

  def metric_not_found_error
    render json: {
      error: {
        name: "The metric name must be one of #{Lanalytics::Metric.all.join(', ')}"
      }
    }, status: 422
  end

end
