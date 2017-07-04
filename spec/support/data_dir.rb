require 'fileutils'

RSpec.configure do |config|
  config.before(:each) do
    FileUtils.mkpath Xikolo.config.data_dir
  end

  config.after(:each) do
    FileUtils.remove_entry_secure Xikolo.config.data_dir
  end
end
