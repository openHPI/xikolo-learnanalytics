
class ResearchCase < ActiveRecord::Base

  has_and_belongs_to_many :users
  has_many :datasource_accesses
  has_many :accessed_datasources, through: :datasource_accesses,  source: :datasource

  alias :contributers :users
  
  def add_contributer(user)
    self.contributers << user
  end

  def accessed_datasources_distinct
    return self.datasource_accesses.to_a.uniq { | ad | "#{ad.user.id}::#{ad.datasource.key}::#{ad.channel.name}" }
  end

  def available_data_schema
    
  end


  # def private?
  #   return not self.public?
  # end
end
