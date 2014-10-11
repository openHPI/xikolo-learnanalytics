// Including the files necessary for the Lanalytics service

//= require jquery

//= require ./lanalytics/model/lanalytics.model.stmt_component.js.coffee
//= require ./lanalytics/model/lanalytics.model.stmt_resource.js.coffee
//= require ./lanalytics/model/lanalytics.model.stmt_verb.js.coffee
//= require ./lanalytics/model/lanalytics.model.stmt_user.js.coffee
//= require ./lanalytics/model/lanalytics.model.exp_api_statement.js.coffee
//= require ./lanalytics/lanalytics.framework.js.coffee
//= require_directory ./lanalytics/plugins

// Files that we do not want to release
//= stub lanalytics/plugins/lanalytics.plugins.newplugintemplate.js.coffee
//= stub lanalytics/plugins/lanalytics.plugins.example.html5videoplayer.js.coffee

lanalytics = new Lanalytics.Framework();