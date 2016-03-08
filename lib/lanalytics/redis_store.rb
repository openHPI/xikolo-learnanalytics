class Lanalytics::RedisStore
  def self.store
    @@store ||= ActiveSupport::Cache::RedisStore.new
    @@store
  end
end
