Lanalytics::RSERVE_CONFIG = YAML.load_file("#{Rails.root}/config/rserve.yml")[Rails.env].with_indifferent_access
