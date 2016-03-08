require 'rserve'
require 'matrix' # allows data transfer to rserve in form of matrices

Lanalytics::RSERVE_CONFIG = YAML.load_file("#{Rails.root}/config/rserve.yml")[Rails.env].with_indifferent_access
