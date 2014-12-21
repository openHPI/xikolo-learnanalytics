class ChannelPresenter < BasePresenter

  def initialize(model, view)
    @channel = model
    super(@channel, view)
  end

  # Interface for styling the access button 
  def present_access_button
    %q{
<a class="btn btn-default btn-md" data-toggle="tooltip" data-placement="top" title="Access the datasource ...">
  <i class="fa fa-arrow-right fa-2x" />
</a>}.html_safe
  end

end