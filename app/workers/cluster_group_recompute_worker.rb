class ClusterGroupRecomputeWorker
  include Sidekiq::Worker

  def perform(job_id, course_id, dimensions, user_uuids)
    results = Lanalytics::Clustering::Dimensions
                .query(course_id, dimensions, user_uuids)
                .entries[0]

    Lanalytics::RedisStore.store.write(job_id, results: results)
  end
end
