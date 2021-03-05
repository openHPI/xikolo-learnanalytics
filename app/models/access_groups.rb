# frozen_string_literal: true

##
# Information about user memberships in access groups.
#
class AccessGroups
  def initialize
    # Preload all access groups (blocking) and the first page of their
    # memberships (non-blocking).
    @memberships_promises = access_groups_memberships_promises
  end

  # Returns an array with all access group names where a user is a member.
  def memberships_for(user_id)
    access_groups_memberships
      .select {|_, user_ids| user_ids.include? user_id }
      .keys
  end

  private

  def access_groups_memberships
    @access_groups_memberships ||=
      @memberships_promises.to_h do |group_name, promise|
        user_ids = Set.new
        promise.each_item {|membership| user_ids.add(membership['user']) }

        [group_name, user_ids]
      end
  end

  def access_groups_memberships_promises
    promises = {}

    access_groups_promise.each_item do |group|
      promises[group['name']] =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          group.rel(:memberships).get(per_page: 10_000)
        end
    end

    promises
  end

  def access_groups_promise
    Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
      account_service.rel(:groups).get(tag: 'access')
    end
  end

  def account_service
    @account_service ||= Restify.new(:account).get.value!
  end
end
