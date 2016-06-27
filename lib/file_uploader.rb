class SizeLimitException < StandardError
  def message
    'Size limit exceeded'
  end
end

class AbsolutePathException < IOError
  def message
    'Supply relative path e.g %w(upload images)'
  end
end

class FileUploader

  require 'net/http'
  include FileHelper
  attr_accessor :file

  #unzip param is not supported here
  def upload(type, file, file_path, description, current_user, unzip=false, course_id=nil, expire_date=nil )
    new_id = SecureRandom.uuid
    file_path = Pathname.new(File.join data_directory, file_path,  File.basename(file.path))
    self.file = type.new id: new_id,
                name:  File.basename(file.path),
                         path: File.join(file_path.relative_path_from data_directory),
                #path: '/reportings',
                description: description,
                user_id: current_user,
                mime_type: 'application/zip' #this is hardcoded for now
    self.file.course_id = course_id if course_id
    self.file.expire_at = expire_date if expire_date

    if self.file.save
      if multipart_request file, self.file.id, File.basename(file.path)
        return new_id
      else
        self.delete_file false
      end
    end
    false
  end

  def save_file
    warn '[DEPRECATED] save_file'
  end

  def delete_file(delete_from_disk=true)
    self.file.delete params: {delete_from_disk: delete_from_disk} if self.file
  end

  BOUNDARY = "RubyMultipartPostFDSFAKLdslfds"
  def multipart_request(file, new_id, filename)
    file.rewind

    uri = URI.parse("#{Acfs::Configuration.current.locate(:file)}/uploaded_files/#{new_id}/upload")

    post_body = []
    post_body << "--#{BOUNDARY}\r\n"
    post_body << "Content-Disposition: form-data; name=\"datafile\"; filename=\"#{to_ascii(filename)}\"\r\n"
    post_body << "Content-Type: text/plain\r\n"
    post_body << "\r\n"
    post_body << file.read
    post_body << "\r\n--#{BOUNDARY}--\r\n"

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = post_body.join
    request["Content-Type"] = "multipart/form-data, boundary=#{BOUNDARY}"

    response = http.request(request)
    response.kind_of? Net::HTTPSuccess
  end

  def to_ascii(str)
    str.encode('ascii', invalid: :replace, undef: :replace, replace: '?')
  end
end
