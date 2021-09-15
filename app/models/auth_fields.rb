# frozen_string_literal: true

class AuthFields
  def headers
    reportable_auth_fields.map {|f| "Auth: #{f}" }
  end

  def values(user_id)
    authorizations = Xikolo::RetryingPromise.new(
      Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
        account_service.rel(:authorizations).get(user: user_id)
      end,
    ).value!.first

    reportable_auth_fields.map do |f|
      authorizations
        .select {|auth| auth['provider'] == f.split('.').first }
        .filter_map {|auth| auth.dig(*f.split('.').drop(1)) }
        .join(',')
    end
  end

  private

  def reportable_auth_fields
    Lanalytics.config.reports['auth_fields'] || []
  end

  def account_service
    @account_service ||= Restify.new(:account).get.value!
  end
end
