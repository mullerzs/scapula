define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  utils = require 'utils'
  vent = require 'vent'

  ajax =
    progCnt  : 0
    queues   : {}
    defaults :
      type        : 'GET'
      dataType    : 'json'
      contentType : 'application/json'
      cache       : false

  types = [ 'POST', 'GET', 'PUT', 'DELETE' ]

  ajax.send = (type, opts, qid) ->
    opts = ajax._setOpts type, opts

    if qid
      dfd = $.Deferred()
      queue = ajax.queues[qid] ?= $({})
      queue.queue (next) ->
        ajax._ajax(opts, dfd).then(next, next)

    dfd?.promise() || ajax._ajax opts

  ajax.get = (opts, qid) ->
    ajax.send 'GET', opts, qid

  ajax.post = (opts, qid) ->
    ajax.send 'POST', opts, qid

  ajax.put = (opts, qid) ->
    ajax.send 'PUT', opts, qid

  ajax.delete = (opts, qid) ->
    ajax.send 'DELETE', opts, qid

  ajax._setOpts = (type, opts) ->
    opts = $.extend {}, ajax.defaults, opts
    opts.type = if type && type in types then type else 'GET'

    if !opts.url
      err = 'No url given!'
    else if opts.type in [ 'POST', 'PUT' ] && !opts.data
      err = 'No data for ' + opts.type + ' request!'

    utils.throwError err, 'ajax' if err

    params = {}

    if auth = utils.getConfig 'auth'
      auth = auth() if _.isFunction auth
      if auth_header = utils.getConfig 'auth_header'
        (opts.headers ?= {})[auth_header] = auth
      else
        params.auth = auth

    params._client_id = client_id if client_id = utils.getConfig 'client_id'

    opts.url = utils.addUrlParams opts.url, params

    opts

  ajax._processError = (error, opts) ->
    ret = []

    if _.isObject error
      error = [ error ] unless _.isArray error

      for err in error
        ret.push err if _.isObject(err) && err.code
    else if error?
      ret = [ code: error ]
    else
      ret = [ code: 'error_internal' ]

    handled = opts?._errors
    unhandled = if handled
      if _.isBoolean handled
        if handled then [] else ret
      else
        handled = [ handled ] unless _.isArray handled
        _.reject ret, (err) -> err.code in handled
    else
      ret

    vent.trigger 'sync:error', unhandled if unhandled.length

    ret

  ajax._ajax = (opts, dfd) ->
    opts.beforeSend = ->
      # vent.trigger 'ajax:start'
      if !opts.noloader
        ajax.progCnt++
        vent.trigger 'ajax:show'

    if !opts.processData? && opts.type isnt 'GET'
      opts.processData = false
      opts.data = JSON.stringify opts.data if _.isObject opts.data

    if base = utils.getConfig 'base'
      opts.url = base + opts.url.replace /^\//, ''

    $.ajax(opts).then( (data, textStatus, jqXHR) ->
      # TODO: make this as default
      ajax_check_code = utils.getConfig 'ajax_check_code'
      legacy_success = !ajax_check_code && data?.success

      if legacy_success || ajax_check_code && jqXHR.status < 400
        data = data.content || {} if legacy_success
        dfd.resolve.call @, data, textStatus, jqXHR if dfd
      else
        error = data?.error unless ajax_check_code
        error = ajax._processError error, opts
        ret = $.Deferred().reject error
        dfd.reject error if dfd

      ret || $.Deferred().resolve data, textStatus, jqXHR

    , (jqXHR, textStatus, errorThrown) ->
      code = if jqXHR.status >= 500
        'internal'
      else if jqXHR.status == 404
        'notfound'
      else if jqXHR.status == 403
        'forbidden'
      else if jqXHR.status == 401
        'unauth'
      else if jqXHR.status == 400
        'req'
      else
        'conn'
      error = ajax._processError "error_#{code}", opts
      dfd.reject error, jqXHR if dfd
      $.Deferred().reject error, jqXHR
    ).always ->
      # vent.trigger 'ajax:end'
      vent.trigger 'ajax:hide' unless opts.noloader || --ajax.progCnt

  ajax
