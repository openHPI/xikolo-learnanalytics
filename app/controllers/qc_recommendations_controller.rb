class QcRecommendationsController< ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  def index
    recommendations = QcRecommendation.all

    if params['offset'].nil?
      @offset = 0
    elsif
      @offset = params['offset']
    end

    respond_with recommendations.offset(@offset)
  end

  def show
    respond_with QcRecommendation.find params[:id]
  end


end