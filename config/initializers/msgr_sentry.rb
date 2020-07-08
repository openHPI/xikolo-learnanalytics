# frozen_string_literal: true

##
# Report all unhandled exceptions in Msgr consumers to Sentry.
#
module MsgrSentryIntegration
  def dispatch(*)
    Raven::Context.clear!

    Raven.capture { super }
  end
end

::Msgr::Consumer.prepend MsgrSentryIntegration
