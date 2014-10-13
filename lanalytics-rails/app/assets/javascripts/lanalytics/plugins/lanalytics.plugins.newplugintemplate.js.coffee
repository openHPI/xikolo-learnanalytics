
class window.Lanalytics.Plugins.NewLanalyticsPlugin extends Lanalytics.Plugin

  # This is the interface method expected by Lanalytics
  # Should return a valid instance of the plugin
  @newInstance: (lanalytics) ->
    return new Lanalytics.Plugins.NewLanalyticsPlugin(lanalytics)

  constructor: (lanalytics) ->
    super(lanalytics)
    this._init()

  _init: ->
    # Do something
    # Register to some events in the DOM, e.g. $(document).on("video-play", @trackVideoPlay)
    $(document).on("video-pause", @trackVideoPause)

  # Handler for the event in the DOM
  # It is important to use '=>' because then 'this' will be binded to NewLanalyticsPlugin instance (in order to access lanalytics)
  # trackVideoPlay: (event, videoPlayerData) =>
  #   @lanalytics.trackCurrentUserDoing("video-play", {
  #     ressource_id: videoPlayerData.ressource
  #   })
