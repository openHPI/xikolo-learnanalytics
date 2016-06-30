require 'active_support/concern'

module DefaultParams
  extend ActiveSupport::Concern

  def process_with_default_params(action, method, params = {})
    process_without_default_params action, method, default_params.merge(params || {})
  end

  included do
    let(:default_params) { {} }
    alias_method_chain :process, :default_params
  end
end

RSpec.configure do |config|
  config.include DefaultParams, type: :controller
end
