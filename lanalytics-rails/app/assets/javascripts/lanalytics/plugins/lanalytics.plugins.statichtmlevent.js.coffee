

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

  # It is important to use '=>' because then 'this' will be binded to StaticHtmlEventTracker instance (in order to access lanalytics)
  processStaticHtmlEvent: (event) =>
    
    clickedElement = event.target
    lanalyticsParentsOfElement = $(clickedElement).parents("[data-lanalytics-resource]")
    if lanalyticsParentsOfElement.length == 0
      throw "No 'data-lanalytics-resource' field could be found in the parents of #{$(clickedElement).html().trim()}."

    eventData = $(clickedElement).data("lanalytics-event")
    stmtVerb = new Lanalytics.Model.StmtVerb(eventData['verb'])

    eventResourceData = lanalyticsParentsOfElement.first().data("lanalytics-resource");
    stmtResource = new Lanalytics.Model.StmtResource(eventResourceData['type'], eventResourceData['uuid'])

    @lanalytics.trackCurrentUserDoing(stmtVerb, stmtResource)