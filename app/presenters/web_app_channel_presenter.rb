class WebAppChannelPresenter < ChannelPresenter

  def present_access_button
    return %Q{
<a class="btn btn-default btn-md" target="_blank" href="#{@channel.url}">
  <i class="fa fa-arrow-right fa-2x" />
</a>
}.html_safe
  end

end