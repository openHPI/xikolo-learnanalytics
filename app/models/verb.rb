# frozen_string_literal: true

class Verb < ApplicationRecord
  has_many :events, dependent: :nullify
end
