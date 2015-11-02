class Verb < ActiveRecord::Base
  has_many :events
end
