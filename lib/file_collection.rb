# frozen_string_literal: true

require 'English'
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
    @base_path.join(path).tap do |file|
      @files[path] = file
    end
  end

  def zip(password)
    # Check if at least one file exists (typically there is only one)
    raise "File '#{@files.first[1]}' does not exist" unless File.exist?(@files.first[1])

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

    raise "Zipping files failed: #{$CHILD_STATUS}" if $CHILD_STATUS.exitstatus > 0

    @base_path.join(path)
  end
end
