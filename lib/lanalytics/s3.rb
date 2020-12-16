# frozen_string_literal: true

require 'aws-sdk-s3'
require 'lanalytics/config'

module Lanalytics
  module S3
    class << self
      def resource
        @resource ||= Aws::S3::Resource.new \
          client: Aws::S3::Client.new(client_config)
      end

      def stub_responses!(stubs)
        @resource = Aws::S3::Resource.new \
          client: Aws::S3::Client.new(stub_responses: stubs)
      end

      private

      def client_config
        Lanalytics.config.s3['connect_info'].transform_keys(&:to_sym)
      end
    end
  end
end
