require 'fileutils'

module FileHelper
  def create_file(path)
    dir = File.dirname(path)

    unless File.directory?(dir)
      FileUtils.mkdir_p(dir)
    end
  end

  def data_directory
    Pathname.new Rails.application.config.data_dir
  end

  def get_dir_name_from_path(path)
    #!TODO @dh: ON some machines we have a leading slash in the relative path?
    File.dirname(path).gsub(/^\//, "")
  end

  def get_requested_document_name(path)
    path.split('/')[-1]
  end

  def get_document_path(path)
    dir_name = get_dir_name_from_path(path)
    requested_filename = get_requested_document_name(path)
    File.join(data_directory, dir_name, requested_filename)
  end

  def get_image_url_for_dialog
    if @course_presenter
      @images_url = course_files_for_dialog_path(@course_presenter.course.id)
    elsif current_user.allowed?('file.uploaded_file.index')
      @images_url = files_dialog_path
    end
  end

  def remove_file(path)
    FileUtils.rm(path)
  end
end
