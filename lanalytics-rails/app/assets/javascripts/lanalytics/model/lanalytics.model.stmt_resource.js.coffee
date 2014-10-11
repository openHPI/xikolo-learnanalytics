window.Lanalytics or= {};
window.Lanalytics.Model or= {};

class window.Lanalytics.Model.StmtResource extends Lanalytics.Model.StmtComponent

  constructor: (type, uuid) ->
    super(type)

    throw "'uuid' argument cannot be nil" if !uuid?
    @uuid = uuid.toString()

  params: ->
    return {
      type: @type,
      uuid: @uuid
    }
