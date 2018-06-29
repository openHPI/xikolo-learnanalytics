require 'active_support/concern'

module S3Stubs
  extend ActiveSupport::Concern

  included do
    let(:s3_stubs) { true }
    before do
      Xikolo::S3.stub_responses! s3_stubs
    end
  end
end

RSpec.configure do |config|
  config.include S3Stubs
end
