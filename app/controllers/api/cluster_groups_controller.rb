class Api::ClusterGroupsController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO: Secure controller
  skip_before_action :require_login, only: [:show, :cluster]

  def show
    group = find_cluster_group

    render json: group
  end

  def index
    groups = ClusterGroup.pluck(:id, :name, :cluster_results)

    render json: groups
  end

  def update
    group = find_cluster_group
    group.update_attributes! cluster_group_params

    render json: group
  end

  def create
    group = ClusterGroup.build(cluster_group_params)
    group.save!

    render json: group
  end

  def delete
    group = find_cluster_group
    group.destroy!

    head :no_content
  end

  private

  def find_cluster_group
    ClusterGroup.find(cluster_group_params[:id])
  end

  def cluster_group_params
    params.permit :id, :user_uuids, :name, :cluster_results
  end
end
