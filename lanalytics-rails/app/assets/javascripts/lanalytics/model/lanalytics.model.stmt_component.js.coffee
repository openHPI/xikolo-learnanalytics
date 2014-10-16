window.Lanalytics or= {};
window.Lanalytics.Model or= {};

class window.Lanalytics.Model.StmtComponent

  constructor: (type) ->
    throw "'type' argument cannot be nil and or empty" if !type? || !type.trim().length
    @type = type.toString()
