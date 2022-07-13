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
    @base_path.join(path).tap {|file|
      @files[path] = file
    }
  end

  def zip(password)
    # Check if at least one file exists (typically there is only one)
    unless File.exist?(@files.first[1])
      raise "File '#{@files.first[1]}' does not exist"
    end

    path = "#{File.basename(@files.first[0], '.*')}.zip"

    if password.present?
      system(
        '/usr/bin/zip',
        '--password',
        password,
        path,
        *names,
        chdir: @base_path,
      )
    else
      system '/usr/bin/zip', path, *names, chdir: @base_path
    end

    raise "Zipping files failed: #{$?}" if $?.exitstatus > 0

    @base_path.join(path)
  end
end
