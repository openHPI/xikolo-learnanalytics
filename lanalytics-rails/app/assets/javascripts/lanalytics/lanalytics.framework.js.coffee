window.Lanalytics or= {};

class window.Lanalytics

  constructor: ->
    @eventQueue = [];
    @plugins = []

  addPlugin: (plugin) ->
#    if plugin instanceof  throw "Plugin is not a Lanalytics.Plugin
    @plugins.push(plugin)

  currentUser: ->
    if gon?.lanalytics?.current_user?
      return gon.lanalytics.current_user # This can also be removed

    return null

  track: (user, verb, ressource, withResult, inContext) ->
    trackEvent = {
      actor: user,
      verb: verb,
      ressource: ressource
    }

    @eventQueue.push(trackEvent)

    @processEventQueue()

    console.debug("New event was tracked:", trackEvent)

    # Verb can a key or an js object
    # Ressource should be an obejct
  trackCurrentUserDoing: (verb, ressource) ->

    user = @currentUser()
    # If a verb is key, we will replace it with the verb that we need to transmit
    verb = Lanalytics.VerbDictionary.getVerb(verb) if typeof verb is "string"

    @track(user, verb, ressource, null, null)

  processEventQueue: ->

#    if eventQueue < 10

    logEvent = @eventQueue.shift()

    $.ajax("/lanalytics/log", {
      type: 'POST',
      cache: false,
      dataType: 'JSON',
      data: logEvent,
      success: (response_data, text_status, jqXHR) ->
        # Do nothing for now
      error: (jqXHR, textStatus, errorThrown) ->
        @eventQueue.push(logEvent)
    })


class window.Lanalytics.VerbDictionary

  @_verbDict = {
    "video-play": {
      verb_id: "http://lanalytics.open.hpi.de/expapi/verbs/video-play"
    },
    "video-pause": {
      verb_id: "http://lanalytics.open.hpi.de/expapi/verbs/video-stop"
    }
  }

  @_undefinedVerbTemplate = {
    id: "http://lanalytics.open.hpi.de/expapi/verbs/undefined"
  }

  @getVerb: (id) ->
    return if VerbDictionary._verbDict[id]? then $.extend({}, VerbDictionary._verbDict[id]) else $.extend({}, VerbDictionary._undefinedVerbTemplate)

class window.Lanalytics.Plugin
  constructor: (@lanalytics) ->

  @newInstance: (lanalyticsTracker) ->
    throw "This function has to be implemented in the subclass."

# The plugin are supposed to be defined under this namesspace
window.Lanalytics.Plugins or= {};

$ ->
  for pluginClassName in Object.keys(Lanalytics.Plugins)
    try
      plugin = Lanalytics.Plugins[pluginClassName].newInstance(lanalytics)
      lanalytics.addPlugin(plugin)
      console.info("Lanalytics.Plugins.#{pluginClassName} found, created and added")
    catch error
      console.warn("Lanalytics.Plugins.#{pluginClassName} found, but could not be instantiated")
      console.error(error.stack)




# TODO:: Provide builder for verb and ressource, e.g. lanalytics.newEventBuilder().setVerb(...).setObject(...).submit()


# Making it globally accessable so that all javascript can use it
# This is done in lanalytics.js
# lanalytics = new Lanalytics()
