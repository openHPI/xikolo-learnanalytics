class Api::TeacherActionsController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO: Secure controller
  skip_before_action :require_login

  def index
    actions = TeacherAction.where(
      cluster_group_id: teacher_action_params[:cluster_group_id]
    )

    render json: actions
  end

  def create
    cluster_group  = find_cluster_group

    teacher_action_is_half_group = params[:half_group] == "1"
    target_users   = user_uuids(cluster_group, teacher_action_is_half_group)

    common_params  = teacher_action_params_with_users(target_users)

    teacher_action = TeacherAction.create(
      common_params.merge(
        action_performed_at: Time.now,
        half_group: teacher_action_is_half_group
      )
    )

    if teacher_action
      Msgr.publish(
        common_params.merge(
          course_id: cluster_group.course_id,
          test: params[:test] == "1"
        ),
        to: "xikolo.lanalytics.teacher_action.create"
      )
    end

    render json: teacher_action
  end

  def recompute
    action = find_teacher_action
    group  = action.cluster_group

    course_id     = group.course_id
    dimensions    = group.cluster_results.each_key.map(&:to_s).sort
    action_users  = action.user_uuids
    control_users = group.user_uuids - action_users

    if control_users.empty?  # Then this was not a half group
      render json: {}
      return
    end

    metrics = {
      control_group: recompute_group(course_id, dimensions, control_users),
      intervention_group: recompute_group(course_id, dimensions, action_users)
    }

    render json: metrics
  end

  private

  def find_teacher_action
    TeacherAction.find(params[:id])
  end

  def find_cluster_group
    ClusterGroup.find(params[:cluster_group_id])
  end

  def recompute_group(course_id, dimensions, user_uuids)
    Lanalytics::Clustering::Metrics
      .metrics(course_id, dimensions, user_uuids)
      .entries[0]
  end

  def teacher_action_params
    params.permit(
      :author_id,
      :richtext_id,
      :cluster_group_id,
      subject: [:en, :de, :fr, :cn]
    )
  end

  def teacher_action_params_with_users(target_users)
    teacher_action_params.merge(user_uuids: target_users)
  end

  def user_uuids(group, is_half_group)
    if is_half_group
      half_uuids(group.user_uuids)
    else
      group.user_uuids
    end
  end

  def half_uuids(user_uuids)
    user_uuids.each_with_index.select{ |_uuid, i|
      i % 2 == 0
    }.map(&:first)
  end
end
