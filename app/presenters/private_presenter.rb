class PrivatePresenter
  extend Forwardable

  def initialize(params)
    params.each_pair do |attribute, value|
      instance_variable_set :"@#{attribute}", value
    end unless params.nil?
  end
end
