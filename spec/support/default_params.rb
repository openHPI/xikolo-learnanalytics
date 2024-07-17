# frozen_string_literal: true

require 'active_support/concern'

module DefaultParams
  extend ActiveSupport::Concern

  included do
    let(:default_params) { {format: :json} }
    prepend InstanceMethods
  end

  module InstanceMethods
    def get(action, **kwargs)
      process(action, method: 'GET', **kwargs)
    end

    def put(action, **kwargs)
      process(action, method: 'PUT', **kwargs)
    end

    def post(action, **kwargs)
      process(action, method: 'POST', **kwargs)
    end

    def patch(action, **kwargs)
      process(action, method: 'PATCH', **kwargs)
    end

    def delete(action, **kwargs)
      process(action, method: 'DELETE', **kwargs)
    end

    def process(action, params: {}, **kwargs)
      params = default_params.merge(params) if params.is_a?(Hash)

      kwargs[:format] ||= params.delete(:format) if params.key?(:format)

      super(action, params:, **kwargs)
    end
  end
end

RSpec.configure do |config|
  config.include DefaultParams, type: :controller
end
