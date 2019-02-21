class SectionConversionsController < ApplicationController
  responders Responders::DecorateResponder,
             Responders::HttpCacheResponder,
             Responders::PaginateResponder
  respond_to :json

  def show
    respond_with SectionConversion.find_by! course_id: params[:course_id]
  end
end
