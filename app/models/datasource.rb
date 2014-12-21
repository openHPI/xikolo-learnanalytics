class Datasource < ActiveRecord::Base

  serialize :settings, Hash

  self.primary_key = 'key'

  def channels
    return []
  end

end
