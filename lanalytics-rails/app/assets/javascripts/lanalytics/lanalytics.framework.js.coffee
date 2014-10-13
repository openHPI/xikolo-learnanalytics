window.Lanalytics or= {};

class window.Lanalytics.Framework

  constructor: ->
    @eventQueue = [];
    @plugins = []

  addPlugin: (plugin) ->
#    if plugin instanceof  throw "Plugin is not a Lanalytics.Plugin
    @plugins.push(plugin)

  currentUser: ->
    if gon?.lanalytics?.current_user?
      return new Lanalytics.Model.StmtUser(gon.lanalytics.current_user.attributes.id)
    else
      return new Lanalytics.Model.StmtUser("ANONYMOUS")

  track: (user, verb, ressource, withResult, inContext) ->
    
    # If a verb is key, we will replace it with the verb that we need to transmit
    verb = Lanalytics.VerbDictionary.getVerb(verb) if typeof verb is "string"
    now = new Date()
    
    experienceStmt = new Lanalytics.Model.ExpApiStatement(user, verb, ressource, now, withResult, inContext)

    @eventQueue.push(experienceStmt)

    @processEventQueue()

    console.debug("New event was tracked:", experienceStmt)

  # Verb can a key or an js object
  # Ressource should be an object that contains the ressource type and the ressource key
  trackCurrentUserDoing: (verb, ressource) ->

    user = @currentUser()
    @track(user, verb, ressource, null, null)

  processEventQueue: ->

#    if eventQueue < 10

    experienceStatement = @eventQueue.shift()

    $.ajax("/lanalytics/log", {
      type: 'POST',
      cache: false,
      dataType: 'JSON',
      data: experienceStatement.params() ,
      success: (response_data, text_status, jqXHR) ->
        # Do nothing for now
      error: (jqXHR, textStatus, errorThrown) =>
        @eventQueue.push(experienceStatement)
    })


class window.Lanalytics.VerbDictionary

  @_verbDict = {
    "video-play": {
      verb_key: "video_play",
      verb_id: "http://lanalytics.open.hpi.de/expapi/verbs/video-play"
    },
    "video-pause": {
      verb_key: "video_pause",
      verb_id: "http://lanalytics.open.hpi.de/expapi/verbs/video-stop"
    },
    "quiz-submitted": {
      verb_key: "quiz_submitted",
      verb_id: 'http://lanalytics.open.hpi.de/expapi/verbs/quiz-submitted'
    }
  }

  @_undefinedVerbTemplate = {
    verb_key: "undefined",
    id: "http://lanalytics.open.hpi.de/expapi/verbs/undefined"
  }

  @getVerb: (id) ->

    if VerbDictionary._verbDict[id]?
      return new Lanalytics.Model.StmtVerb(VerbDictionary._verbDict[id].verb_key)
    else
      return new Lanalytics.Model.StmtVerb(@_undefinedVerbTemplate.verb_key)



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
