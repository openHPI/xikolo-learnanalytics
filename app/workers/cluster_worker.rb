class ClusterWorker
  include Sidekiq::Worker

  def perform(job_id, num_centers, course_id, dimensions)
    results = Lanalytics::Clustering::Runner.cluster(
      num_centers,
      course_id,
      dimensions
    )

    Lanalytics::RedisStore.store.write(job_id, results: results)
  end
end
