window.Lanalytics or= {};
window.Lanalytics.Model or= {};

class window.Lanalytics.Model.ExpApiStatement

  constructor: (user, verb, resource, timestamp = new Date(), @with_result = {}, @in_context = {}) ->
    #  ::TODO Some assertions to ensure the datamodel
    throw "'user' argument cannot be nil and should be Lanalytics::Model::StmtUser" unless user instanceof Lanalytics.Model.StmtUser
    @user = user

    throw "'verb' argument cannot be nil and should be Lanalytics::Model::StmtVerb" unless verb instanceof Lanalytics.Model.StmtVerb
    @verb = verb

    throw "'resource' argument cannot be nil and should be Lanalytics::Model::StmtResource" unless resource instanceof Lanalytics.Model.StmtResource
    @resource = resource

    timestamp ||= DateTime.now
    throw "'timestamp' argument should be DateTime or String" unless timestamp instanceof Date or timestamp instanceof String
    timestamp = new Date(timestamp) if timestamp instanceof String
    @timestamp = timestamp


  # This is the serialization  
  serialize: ->
    return JSON.stringify(@params)

  params: ->
    return {
      user: @user.params(),
      verb: @verb.params(),
      resource: @resource.params(),
      timestamp: @timestamp,
      with_result: @with_result,
      in_context: @in_context
    }

    
    



