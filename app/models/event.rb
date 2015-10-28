class Event < ActiveRecord::Base
  belongs_to :verb
  belongs_to :resource
end
