require 'aws-sdk-s3'

module Xikolo
  class S3
    class << self
      def bucket_for(name)
        resource.bucket(Xikolo.config.s3["buckets"][name.to_s])
      end

      def resource
        @resource ||= Aws::S3::Resource.new \
          client: Aws::S3::Client.new(Xikolo.config.s3["connect_info"].symbolize_keys)
      end

      def stub_responses!(stubs)
        @resource = Aws::S3::Resource.new \
          client: Aws::S3::Client.new(stub_responses: stubs)
      end
    end
  end
end
