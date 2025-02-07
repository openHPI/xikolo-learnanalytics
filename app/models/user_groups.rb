# frozen_string_literal: true

class UserGroups
  def initialize(*)
    @users = {}
    @groups = keys.to_h do |group_key|
      group_name = group_name(group_key)
      user_ids = account_service.rel(:group).get(id: group_name).then do |group|
        ids = []
        Xikolo.paginate(
          group.rel(:members).get,
        ) do |member|
          ids << member['id']
        end
        ids
      end.value!
      [group_key, user_ids]
    end
  end

  def keys
    []
  end

  def group_name(_)
    nil
  end

  def groups_for_user(user_id)
    @users[user_id] ||= keys.select do |key|
      @groups[key].include? user_id
    end
  end

  private

  def account_service
    @account_service ||= Restify.new(:account).get.value!
  end

  class GlobalGroups < UserGroups
    def keys
      Lanalytics.config.global_permission_groups
    end

    def group_name(group_key)
      "xikolo.#{group_key}"
    end
  end

  class CourseGroups < UserGroups
    def initialize(course_code)
      @course_code = course_code
      super
    end

    def keys
      Lanalytics.config.course_groups.keys
    end

    def group_name(group_key)
      ['course', @course_code, group_key].join('.')
    end
  end
end
