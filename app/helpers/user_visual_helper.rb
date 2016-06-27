module UserVisualHelper
  include Rails.application.routes.url_helpers

  def user_visual_path image_id, size = nil
    if image_id
      path = file_path id: image_id
      if size
        path += "/size/#{size}"
      end
      path
    else
      if size
        filename = 'user_'+ size.to_s + '.png'
      else
        filename = 'user.png'
      end
      ActionController::Base.helpers.asset_path 'defaults/' + filename
    end
  end
end