class QueryController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO secure controller when reaearcher interface is published
  skip_before_action :require_login, only: [:show]

  def show
    unless datasource_identifiers.include? params[:datasource]
      render json: {}
      return
    end
    datasource = get_datasource(params[:datasource])
    datasource.exec do |client|
      if params[:search].present?
        render json: client.search(index: datasource.index, body: params[:body])
      elsif params[:count].present?
        render json: client.count(index: datasource.index, body: params[:body])
      end
    end
  end

  private

  def get_datasource(identifier)
    datasource = Lanalytics::Processing::DatasourceManager.get_datasource(identifier)
  end

  def datasource_identifiers
    ['exp_api_elastic']
  end
end
