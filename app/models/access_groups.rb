# frozen_string_literal: true

##
# Information about user memberships in access groups.
#
class AccessGroups
  def initialize
    # Preload the access groups
    @access_groups = access_groups
  end

  # Returns an array with all access group names where a user is a member.
  def memberships_for(user)
    user_groups(user).intersection(@access_groups)
  end

  private

  def user_groups(user)
    Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) do
      user.rel(:groups).get(per_page: 1_000)
    end.value!.pluck('name')
  end

  def access_groups
    Xikolo::Retryable.new(max_retries: 3, wait: 20.seconds) do
      account_service.rel(:groups).get(tag: 'access')
    end.value!.pluck('name')
  end

  def account_service
    @account_service ||= Restify.new(:account).get.value!
  end
end
