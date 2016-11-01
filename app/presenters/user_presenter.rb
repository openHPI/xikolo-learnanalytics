class UserPresenter < Presenter
  include Rails.application.routes.url_helpers
  include UserVisualHelper

  def_delegators :user, :id, :email, :name, :first_name, :last_name, :display_name, :born_at, :is_admin, :to_param, :blurb, :language, :affiliated, :created_at
  def_delegator :image, :path, :image_path
  def_delegator :image, :description, :image_description
  def_delegator :image, :id, :image_id

  attr_accessor :user, :image


  def user_visual size = nil
    # use helper
    return user_visual_path user.image_id, size
  end


  def self.create(user)
    unless user.nil?
      if user.image_id
        image = Xikolo::File::Image.find user.image_id
        Acfs.run
        self.new({user: user, image: image})
      else
        self.new({user: user, image: nil})
      end
    end
  end

  def full_name
    self.first_name + ' ' + self.last_name
  end

  def self.create_for_many(users)
    users.collect { |user| create(user) }
  end
end
