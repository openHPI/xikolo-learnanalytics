class NullPool
  def initialize(*)
  end

  def post(*args)
    yield(*args)
  end
end
