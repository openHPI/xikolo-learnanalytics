$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "lanalytics/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "lanalytics"
  s.version     = Lanalytics::VERSION
  s.authors     = ['Open HPI Dev Team']
  s.email       = ['xikolo-dev@hpi.uni-potsdam.de']
  s.homepage    = "http://lanalytics.openhpi.de"
  s.summary     = "Ruby / Rails client gem for the Lanalytics Service"
  s.description = "Ruby / Rails client gem for the Lanalytics Service as found on: git@openhpi-utils.hpi.uni-potsdam.de:gerardo.navarro-suarez/lanalytics.git"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0"
  s.add_dependency 'gon'
  s.add_dependency 'msgr', '~> 0.10'

  s.add_development_dependency 'coffee-rails', '~> 4.0.0'

end
