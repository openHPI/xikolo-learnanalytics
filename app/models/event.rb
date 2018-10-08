class Event < ApplicationRecord
  belongs_to :verb
  belongs_to :resource
end
