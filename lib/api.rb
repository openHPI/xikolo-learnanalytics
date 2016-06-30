require 'restify'

class API
  class << self
    def services
      Xikolo::Lanalytics::Application.config.services ||= Hash.new
    end

    def [](key)
      Restify.new(services[key]).get.value!
    end

    def add(name, url)
      services[name.to_sym] = url
    end
  end
end
