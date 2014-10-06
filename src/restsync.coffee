define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  ajax = require 'ajax'
  utils = require 'utils'
  vent = require 'vent'

  methodMap =
    create : 'POST'
    read   : 'GET'
    update : 'PUT'
    delete : 'DELETE'

  Backbone.sync = (method, model, options) ->
    type = methodMap[method]

    utils.throwError 'Invalid sync method!' unless type

    params = {}
    options ?= {}

    success = options.success
    error = options.error
    delete options.success
    delete options.error

    params.url = options.url

    if !params.url && model
      params.url = utils.getProp model, 'url'
      queueId = params.url
      params.url = '/api' + params.url

    utils.throwError 'No url for request!' unless params.url

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
            model.cloneAttrs children: 'id', skipInternal: true
          else
            model.dirtyAttrs clear: true

        vent.trigger 'save:start'

    req = ajax.send type, _.extend(params, options), queueId

    req.then( (data, textStatus, jqXHR) ->
      if method isnt 'read'
        vent.trigger 'save:ok'

        if !options.ids
          if method is 'delete'
            data || {}
          else
            attrs = options.refreshAttrs || model.refreshAttrs
            if !attrs
              data = if method is 'create' then id: data.id else {}
            else if !_.isBoolean attrs
              attrs = [ attrs ] unless _.isArray attrs
              attrs.push 'id' if method is 'create' && 'id' not in attrs
              data = _.pick data, attrs

      $.Deferred().resolve data, textStatus, jqXHR
    ).done(success).fail(error)
