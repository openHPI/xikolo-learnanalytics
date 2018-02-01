class ClusterDimensionsController < ApplicationController

  def index
    verbs   = Lanalytics::Clustering::Dimensions::ALLOWED_VERBS
    metrics = Lanalytics::Clustering::Dimensions::ALLOWED_METRICS

    render json: (verbs + metrics).sort
  end

end
