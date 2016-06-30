['config/services.yml', "config/services.#{Rails.env}.yml"].each do |file_name|
  next unless File.exist? file_name
  config = YAML.load(File.read(file_name))
  next unless config.key?(Rails.env) && config[Rails.env].key?('services')
  config[Rails.env]['services'].each do |key, value|
    API.add(key, value)
  end
end
