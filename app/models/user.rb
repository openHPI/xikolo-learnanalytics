class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_and_belongs_to_many :research_cases

  validates :password, length: { minimum: 3 }
  validates :password, confirmation: true
  validates :password_confirmation, presence: true

  validates :email, uniqueness: true
end