class Lanalytics::SnapshotController < ApplicationController

  def snapshot

    @courses = Course.all

    @courses.each do | course |
      domain_model_event = {
        verb: 'CREATE',
        object: course
      }
      Msgr.publish(domain_model_event, to: "lanalytics.domain.model")
    end

    render json: { status: "ok" }
  end

end