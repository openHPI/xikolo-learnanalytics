class QcRecommendationsController< ApplicationController
  responders Responders::ApiResponder,
             Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder

  respond_to :json

  def index
    respond_with QcRecommendation.all
  end

  def show
    respond_with QcRecommendation.find params[:id]
  end

end