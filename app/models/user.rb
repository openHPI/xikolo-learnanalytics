class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_and_belongs_to_many :research_cases
  has_many :datasource_accesses
  has_many :accessed_datasources, through: :datasource_accesses, source: :datasource

  validates :password, length: { minimum: 3 }
  validates :password, confirmation: true
  validates :password_confirmation, presence: true

  validates :email, uniqueness: true, presence: true, email_format: { message: 'The given Email is not looking good' }
  validates :username, presence: true, format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters"}

  def datasource_accesses
    return []
  end
end