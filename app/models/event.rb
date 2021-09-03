# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :verb, optional: true
  belongs_to :resource, optional: true
end
