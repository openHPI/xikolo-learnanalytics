require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Xikolo::Lanalytics
  class Application < Rails::Application
    config.api_only = true
    config.autoload_paths += %W(#{config.root}/lib)
  end

  def self.rake?
    @rake
  end

  def self.rake=(value)
    @rake = !!value
  end
end
