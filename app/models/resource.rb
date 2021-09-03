# frozen_string_literal: true

class Resource < ApplicationRecord
  has_many :events, dependent: :nullify
end
