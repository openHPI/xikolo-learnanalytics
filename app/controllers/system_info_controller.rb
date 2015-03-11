class SystemInfoController < ApplicationController
  respond_to :json

  include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  newrelic_ignore

  skip_before_action :require_login

  def show
    deb_version = ENV['DEB_VERSION'] ||
                  "0.0+t#{Time.now.utc.strftime('%Y%m%d%H%M')}+b0-1"

    version, time, build_number = deb_version.split('-')[0].split('+')
    respond_with(
      running:      true,
      build_time:   DateTime.strptime(time, 't%Y%m%d%H%M').iso8601,
      build_number: build_number[1..-1].to_i,
      version:      version,
      hostname:     Socket.gethostname
    )
  end
end
