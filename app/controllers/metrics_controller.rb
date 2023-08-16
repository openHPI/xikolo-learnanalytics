# frozen_string_literal: true

require 'lanalytics/metric/base'

class MetricsController < ApplicationController
  def index
    metrics = Lanalytics::Metric.all.map do |name|
      metric = Lanalytics::Metric.resolve(name)
      {
        name: name.underscore,
        available: metric.available?,
        datasources: metric.datasource_keys,
        description: metric.desc,
        required_params: metric.required_params,
        optional_params: metric.optional_params,
      }
    end

    render(json: metrics)
  end

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

    render json: metric.query(**metric_params)
  end

  private

  def metric_params
    params.except(:format, :controller, :action, :name).to_unsafe_h.symbolize_keys
  end

  def metric_not_found_error
    render json: {
      error: {
        name: "The metric name must be one of #{Lanalytics::Metric.all.join(', ')}",
      },
    }, status: :unprocessable_entity
  end

  def metric_not_available_error
    render json: {
      error: {
        name: 'The metric is not available',
      },
    }, status: :unprocessable_entity
  end
end
