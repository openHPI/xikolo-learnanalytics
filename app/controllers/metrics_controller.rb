require_dependency 'lanalytics/metric/base'

class MetricsController < ApplicationController

  def show
    name = params[:name]
    metric = Lanalytics::Metric.resolve(name)

    if metric.nil?
      metric_not_found_error
      return
    end

    unless metric.available?
      metric_not_available_error
      return
    end

    render json: metric.query(metric_params)
  end

  def index
    render(json: Lanalytics::Metric.all.map { |name|
      metric = Lanalytics::Metric.resolve(name)
      {
        name: name.underscore,
        available: metric.available?,
        datasources: metric.datasource_keys,
        description: metric.desc,
        required_params: metric.required_params,
        optional_params: metric.optional_params
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

  def metric_not_available_error
    render json: {
      error: {
        name: 'The metric is not available'
      }
    }, status: 422
  end

end
