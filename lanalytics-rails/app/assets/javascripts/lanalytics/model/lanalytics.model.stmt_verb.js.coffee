window.Lanalytics or= {};
window.Lanalytics.Model or= {};

class window.Lanalytics.Model.StmtVerb extends window.Lanalytics.Model.StmtComponent

  constructor: (type) ->
    super(type)

  params: ->
    return {
      type: @type,
    }
