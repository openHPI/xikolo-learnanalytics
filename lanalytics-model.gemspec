$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "lanalytics/model/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "lanalytics-model"
  s.version     =  Lanalytics::Model::VERSION
  s.authors     = ['Open HPI Dev Team']
  s.email       = ['xikolo-dev@hpi.uni-potsdam.de']
  s.homepage    = "http://lanalytics.openhpi.de"
  s.summary     = "Ruby / Rails client gem for the Lanalytics Service"
  s.description = "Ruby / Rails client gem for the Lanalytics Service as found on: git@openhpi-utils.hpi.uni-potsdam.de:gerardo.navarro-suarez/lanalytics.git"
  s.license     = "MIT"

  s.files = Dir["lib/lanalytics/model/**/*"]

  s.add_dependency 'json'
end
