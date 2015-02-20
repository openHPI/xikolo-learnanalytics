class WebDocumentationChannel < Channel
  attr_reader :documentation

  def initialize(name, usage, documentation_url, documentation)
    super(name, usage, documentation_url)
    @documentation = documentation
  end

end