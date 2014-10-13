# This plugin was created for the xikolo-web application in order to track the events from the (custom) video player
# This is exactly the situation for which a olugin is designed for ...
class window.Lanalytics.Plugins.Html5VideoPlayerTracker extends Lanalytics.Plugin

  # This is the interface method expected by Lanalytics
  # Should return a valid instance of the plugin
  @newInstance: (lanalytics) ->
    return new Lanalytics.Plugins.Html5VideoPlayerTracker(lanalytics)

  constructor: (lanalytics) ->
    super(lanalytics)
    this._init()

  _init: ->
    $(document).on("video-play", @trackVideoPlay)
    $(document).on("video-pause", @trackVideoPause)

  # It is important to use '=>' because then 'this' will be binded to StaticHtmlEventTracker instance (in order to access lanalytics)
  trackVideoPlay: (event, videoPlayerData) =>
    stmtResource = new Lanalytics.Model.StmtResource("Item", videoPlayerData.ressource)
    @lanalytics.track("video-play", stmtResource)

  trackVideoPause: (event, videoPlayerData) =>
    stmtResource = new Lanalytics.Model.StmtResource("Item", videoPlayerData.ressource)
    @lanalytics.trackCurrentUserDoing("video-pause", stmtResource)
