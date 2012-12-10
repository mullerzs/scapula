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

    if !options.url && model
      params.url = utils.getProp model, 'url'
      queueId = params.url
      params.url = '/api' + params.url

    utils.throwError 'No url for request!' unless options.url || params.url

    if model
      if method is 'read'
        pars = _.clone utils.getProp(model, 'urlParams')

        if !options.all
          pars ?= {}
          pars.deleted = 'eq:0'

        params.data = pars if _.isObject pars
      else
        if options.ids
          params.data = if _.isArray(options.ids)
            options.ids
          else
            [ options.ids ]
        else if !options.data && method isnt 'delete'
          attrs = if method is 'create'
            model.cloneAttrs children: 'id', skipInternal: true
          else
            model.dirtyAttrs clear: true
          params.data = attrs

        vent.trigger 'save:start'

    req = ajax.send type, _.extend(params, options), queueId

    # TODO: crud error display?
    req.pipe( (data, textStatus, jqXHR) ->
      data = data.content if _.isObject data
      if !options.ids
        if method is 'create'
          data = id: data.id
        else if method is 'read'
          if options.all
            model._deleted_items = _.filter data, (item) -> item.deleted
            data = _.filter data, (item) -> !item.deleted
        else
          data = {}

      if method isnt 'read'
        if options.saveOkMsg
          vent.trigger 'save:status:show', options.saveOkMsg
        else
          vent.trigger 'save:ok'

      $.Deferred().resolve data, textStatus, jqXHR
    ).fail( ->
      vent.trigger 'api:error', method + ' ' + params.url
      vent.trigger 'save:error' unless method is 'read'
    ).done(success).fail(error)
