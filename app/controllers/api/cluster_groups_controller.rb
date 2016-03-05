class Api::ClusterGroupsController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO: Secure controller
  skip_before_action :require_login

  def show
    group = find_cluster_group

    render json: group
  end

  def index
    groups = ClusterGroup.where(course_id: cluster_group_params[:course_id])
                         .pluck(:id, :name, :cluster_results)
                         .map do |group|
      {
        id: group[0],
        name: group[1],
        cluster_results: group[2],
      }
    end

    render json: groups
  end

  def update
    group = find_cluster_group
    group.update_attributes! cluster_group_params

    render json: group
  end

  def create
    group = ClusterGroup.create(cluster_group_params)

    render json: group
  end

  def destroy
    group = find_cluster_group
    group.destroy!

    head :no_content
  end

  def recompute
    group = find_cluster_group

    dimensions_data = Lanalytics::Clustering::Dimensions.query(
      group.course_id,
      group.cluster_results.each_key.map(&:to_s).sort,
      group.user_uuids
    ).entries[0]

    render json: dimensions_data
  end

  private

  def find_cluster_group
    ClusterGroup.find(cluster_group_params[:id])
  end

  def cluster_group_params
    params.permit(:id, :name, :course_id)
          .merge(
            user_uuids: params[:user_uuids],
            cluster_results: params[:cluster_results]
          )
          .reject{|k,v| v.blank?}
  end
end
