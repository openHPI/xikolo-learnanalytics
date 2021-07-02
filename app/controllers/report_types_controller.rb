# frozen_string_literal: true

class ReportTypesController < ApplicationController
  responders Responders::HttpCacheResponder

  respond_to :json

  def index
    respond_with report_types
  end

  private

  def report_types
    return [] unless Lanalytics.config.reports&.key? 'types'

    report_classes = Lanalytics.config.reports['types'].map do |type|
      if type.is_a?(Hash)
        key = type.keys.first
        type[key].map {|t| "Reports::#{key.camelize}::#{t.camelize}" }
      else
        "Reports::#{type.camelize}"
      end
    end.flatten

    report_classes.map {|klass| klass.constantize.form_data }
  end
end
