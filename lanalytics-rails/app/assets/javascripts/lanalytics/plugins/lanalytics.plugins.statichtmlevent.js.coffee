

class window.Lanalytics.Plugins.StaticHtmlEventTracker extends Lanalytics.Plugin

  # This is the interface method expected by Lanalytics
  # Should return a valid instance of the plugin
  @newInstance: (lanalytics) ->
    return new Lanalytics.Plugins.StaticHtmlEventTracker(lanalytics)

  constructor: (lanalytics) ->
    super(lanalytics)
    this._init()

  _init: ->
    $("*[data-lanalytics-event]").on("click", @processStaticHtmlEvent)

  # It is important to user '=>' because this is how CoffeeScript wants us to implement callbacks
  @processStaticHtmlEvent: (event) =>
    if $(this).parents("[data-lanalytics-ressource]").length == 0
      throw "No 'data-lanalytics-ressource' field could be found in the parents of #{$(this).html().trim()}."

    eventObjectId = $(this).parents("[data-lanalytics-ressource]").first().data("lanalytics-object");

    lanalytics.trackCurrentUserDoing($(this).data("lanalytics-event").verb, {
      ressource_id: eventObjectId
    })