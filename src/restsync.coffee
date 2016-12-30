define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  ajax = require './ajax'
  config_utils = require './config-utils'
  utils = require 'scapula-utils'

  methodMap =
    create : 'POST'
    read   : 'GET'
    update : 'PUT'
    delete : 'DELETE'

  Backbone.sync = (method, model, options) ->
    type = methodMap[method]

    throw new Error 'Invalid sync method!' unless type

    params = {}
    options ?= {}

    options.synctype = method
    options.cid = cidname if (cidname = config_utils.getConfig 'client_id_name')

    success = options.success
    error = options.error
    delete options.success
    delete options.error

    params.url = options.url

    if !params.url && model
      params.url = utils.getProp model, 'url'
      queueId = params.url
      params.url = '/api' + params.url

    throw new Error 'No url for request!' unless params.url

    if model
      if method is 'read'
        params.data = _.extend {}, utils.getProp(model, 'urlParams'), options?.urlParams
      else
        if options.ids
          params.data = if _.isArray(options.ids)
            options.ids
          else
            [ options.ids ]
        else if !options.data && method isnt 'delete'
          params.data = if method is 'create'
            model.cloneAttrs
              children     : 'auto'
              skipInternal : true
              cid          : options.cid
          else
            model.dirtyAttrs clear: true

    ajax.send(type, _.extend(params, options), queueId)
      .done(success).fail(error)
