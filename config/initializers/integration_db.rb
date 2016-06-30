if Rails.env == 'integration'
  require 'rack/remote'
  require 'database_cleaner'

  DatabaseCleaner.strategy = :truncation

  def __clean_with_truncate
    Rails.logger.info '>>> Clean database with TRUNCATE'
    DatabaseCleaner.clean
  end

  XiIntegration.hook :test_setup do
    __clean_with_truncate
  end

  __clean_with_truncate
end
