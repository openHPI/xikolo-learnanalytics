class ResearchCase < ActiveRecord::Base

  has_many :collaborators # through user class

  def public?
    return self.public
  end

  def private?
    return not self.public?
  end
end
