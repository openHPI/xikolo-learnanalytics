class ClusterJobsController < ApplicationController

  def show
    render json: Rails.cache.fetch(params[:id])
  end

  rfc6570_params create: [:num_centers, :course_id, :dimensions]

  def create
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

  private

  def cluster_params
    params.permit :num_centers, :course_id, dimensions: []
  end
end
