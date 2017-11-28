class FileCollection
  def initialize(base_path)
    @files = {}
    @base_path = base_path
  end

  def count
    @files.count
  end

  def names
    @files.keys
  end

  def make(path)
    @base_path.join(path).tap { |file|
      @files[path] = file
    }
  end

  def zip(password)
    path = "#{File.basename(@files.first[0], '.*')}.zip"
    password = password.present? ? "--password #{password}" : ''

    system "zip #{password} #{path} #{names.join(' ')}", chdir: @base_path

    raise "Zipping files failed: #{$?}" if $?.exitstatus > 0

    @base_path.join(path)
  end
end
