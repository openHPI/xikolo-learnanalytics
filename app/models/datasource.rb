class Datasource < ActiveRecord::Base

  serialize :settings, Hash
  attr_reader :channels

  self.primary_key = 'key'

  def setup_channels(current_user)
    @channels = []
  end

end
