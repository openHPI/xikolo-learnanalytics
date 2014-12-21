
class ResearchCase < ActiveRecord::Base

  has_and_belongs_to_many :users

  alias :contributers :users
  
  def add_contributer(user)
    self.contributers << user
  end


  def available_data_schema
    
  end


  # def private?
  #   return not self.public?
  # end
end
