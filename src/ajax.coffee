define (require) ->
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

  ajax._setOpts = (type, opts) ->
    opts = $.extend {}, ajax.defaults, opts
    opts.type = if type && type in types then type else 'GET'

    if !opts.url
      err = 'No url given!'
    else if opts.type in [ 'POST', 'PUT' ] && !opts.data
      err = 'No data for ' + opts.type + ' request!'

    utils.throwError err, 'ajax' if err

    ### DEBUG
    d = new Date()
    debugUrlParams = '_=' + d.getTime() + '&_o=' + d.getTimezoneOffset()
    opts.url += (if opts.url.match /\?/ then '&' else '?') + debugUrlParams
    ###

    opts

  ajax._processError = (error) ->
    ret = []

    if _.isObject error
      error = [ error ] unless _.isArray error

      for err in error
        ret.push err if _.isObject(err) && err.code
    else if error?
      ret = [ code: error ]

    unauth = _.find ret, (err) ->
      err.code in [ 'error_sestimeout', 'error_unauth' ]

    vent.trigger 'ajax:unauth', unauth.code if unauth

    if ret.length then ret else undefined

  ajax._ajax = (opts, dfd) ->
    opts.beforeSend = ->
      # vent.trigger 'ajax:start'
      if !opts.noloader
        ajax.progCnt++
        vent.trigger 'ajax:show'

    if !opts.processData? && opts.type isnt 'GET'
      opts.processData = false
      opts.data = JSON.stringify opts.data if _.isObject opts.data

    $.ajax(opts).then( (data, textStatus, jqXHR) ->
      if data?.success
        data = data.content || {}
        dfd.resolve.call @, data, textStatus, jqXHR if dfd
      else
        error = ajax._processError data?.error
        vent.trigger 'ajax:error', [ code: 'error_internal' ] unless error
        ret = $.Deferred().reject error
        dfd.reject error if dfd

      ret || jqXHR

    , (jqXHR, textStatus, errorThrown) ->
      vent.trigger 'ajax:error', [ code: 'error_req' ]

      dfd.reject() if dfd
      $.Deferred().reject()
    ).always ->
      # vent.trigger 'ajax:end'
      vent.trigger 'ajax:hide' unless opts.noloader || --ajax.progCnt

  ajax
