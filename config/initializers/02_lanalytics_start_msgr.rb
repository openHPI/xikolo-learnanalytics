# run before integration initializers

# We only want the Msgr.client from the 'msgr' gem to start only for the rails server, not for rake tasks or rails c

# We do not want this initializer to be executed within a rake task
# See in http://stackoverflow.com/questions/7508170/rails-3-1-how-to-run-an-initializer-only-for-the-web-app-rails-server-unicorn
# And see in http://stackoverflow.com/questions/13506690/how-to-determine-if-rails-is-running-from-cli-console-or-as-server
if defined?(Rails::Server) && !Xikolo::Lanalytics.rake?
  Rails.application.config.after_initialize do
    # Turn of the Msgr.Client
    Msgr.client.start unless Msgr.client.running?
  end
end
