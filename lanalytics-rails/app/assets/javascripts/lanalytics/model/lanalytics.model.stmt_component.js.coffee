window.Lanalytics or= {};
window.Lanalytics.Model or= {};

class window.Lanalytics.Model.StmtComponent

  constructor: (type) ->
    throw "'type' argument cannot be nil and cannot be converted to string" if !type?
    @type = type.toString()
