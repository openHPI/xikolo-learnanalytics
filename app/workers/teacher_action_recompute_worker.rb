class TeacherActionRecomputeWorker
  include Sidekiq::Worker

  def perform(job_id, course_id, dimensions, control_group, intervention_group)
    results = {
      control_group: recompute(course_id, dimensions, control_group),
      intervention_group: recompute(course_id, dimensions, intervention_group)
    }

    Rails.cache.write(job_id, results: results)
  end

  def recompute(course_id, dimensions, user_uuids)
    Lanalytics::Clustering::Dimensions
      .query(course_id, dimensions, user_uuids)
      .entries[0]
  end

end
