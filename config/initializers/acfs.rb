# Load service configuration
Acfs.configure do
  load 'config/services.yml'
  load "config/services.#{Rails.env}.yml" if File.exist? "config/services.#{Rails.env}.yml"
end
