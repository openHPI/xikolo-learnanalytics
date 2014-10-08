require 'json'

class Lanalytics::Model::StmtComponent
  attr_accessor :type

  def initialize(type)
    raise "'type' argument cannot be nil" unless type.is_a? String or type.is_a? Symbol
    @type = type.to_sym
  end

  def == (other)
    unless other.class == self.class
      return false
    end
    return @type == other.type
  end
  alias_method :eql?, :==

end