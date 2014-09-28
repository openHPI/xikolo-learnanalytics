LANALYTICS_CONFIG_FILE = "#{Rails.root}/config/lanalytics.yml"
LANALYTICS_CONFIG = YAML.load_file(LANALYTICS_CONFIG_FILE).with_indifferent_access
LANALYTICS_CONFIG = LANALYTICS_CONFIG[Rails.env] || LANALYTICS_CONFIG

unless LANALYTICS_CONFIG.has_key?(:snapshot_handlers)
  raise "No snapshot handlers defined in #{LANALYTICS_CONFIG_FILE}. Please include it"
end