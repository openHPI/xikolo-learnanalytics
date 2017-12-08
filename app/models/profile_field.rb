class ProfileField < ActiveRecord::Base

  scope :sensitive, -> { where(sensitive: true) }
  scope :omittable, -> { where(omittable: true) }

end
