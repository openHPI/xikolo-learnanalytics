class Api::TeacherActionsController < ApplicationController
  protect_from_forgery with: :null_session

  # TODO: Secure controller
  skip_before_action :require_login

  def create
    cluster_group  = ClusterGroup.find(params[:id])
    target_users   = user_uuids(cluster_group, params[:half_group])
    common_params  = teacher_action_params(target_users)

    teacher_action = TeacherAction.create(
      common_params.merge(action_performed_at: Time.now)
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

  private

  def teacher_action_params(target_users)
    params.permit(:author_id, :richtext_id, subject: [:en, :de, :fr, :cn])
          .merge(
            cluster_group_id: params[:id],
            user_uuids: target_users
          )
  end

  def user_uuids(group, is_half_group)
    if is_half_group == '1'
      half_group(group.user_uuids)
    else
      group.user_uuids
    end
  end

  def half_group(user_uuids)
    user_uuids.each_with_index.select{ |_uuid, i|
      i % 2 == 0
    }.map(&:first)
  end
end
