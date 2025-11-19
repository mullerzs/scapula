define (require) ->
  _ = require 'underscore'
  vent = require 'vent'
  utils = require 'utils'

  ws =
    _sockets : {}
    MAX_RETRY_MS : 30000
    PING         : 'ping'

  ws.connect = (name, url, opts = {}) ->
    return unless window.WebSocket && name && url
    return ws._sockets[name].conn if !opts.retry && ws._sockets[name]

    if !url.match /^wss?\:\/\//
      url = utils.getHost() + url if url.match /^\//
      url = (if utils.getProtocol() is 'https:' then 'wss' else 'ws') +
        "://#{url}"

    # console.log "WS[#{name}] CONNECT: #{url}"

    socket = ws._sockets[name] ?= {}
    subprot = if opts.subprot?
      if opts.subprot is false then null else opts.subprot
    else if !_.isFunction(auth = utils.getConfig 'auth')
      auth

    _url = if opts.auth?
      utils.addUrlParams url,
        auth: if _.isFunction opts.auth
            opts.auth()
          else
            opts.auth
    else
      url

    _url = utils.addUrlParams _url,
        _: Date.now()
      ,
        merge: true

    socket.conn = new WebSocket _url, subprot
    socket.attempts = 1 unless opts.retry

    socket.conn.onopen = ->
      # console.log "WS[#{name}] IS OPEN"
      socket.attempts = 1
      vent.trigger "websocket:#{name}:open", socket.conn, opts

    socket.conn.onclose = (e) ->
      # console.log "WS[#{name}] CLOSED (code: #{e.code}, wasClean: #{e.wasClean})"
      clearTimeout socket._reconnect_timer

      if e.wasClean && e.code in [ 1000, 1001 ]
        delete ws._sockets[name]
      else
        socket.attempts ?= 1
        to = ws.getReconnectTimeout socket.attempts
        # console.log "WS[#{name}] RECONNECT IN #{to} ms"

        socket._reconnect_timer = setTimeout ->
          socket.attempts++
          ws.connect name, url, _.extend {}, opts, retry: true
        , to

      vent.trigger "websocket:#{name}:close", e

    if opts.msgevent
      # console.log "WS[#{name}] SET MESSAGING TO '#{opts.msgevent}'"
      socket.conn.onmessage = (e) ->
        # console.log "WS[#{name}] INCOMING MSG: " + e.data
        msgevent = opts.msgevent

        if e.data instanceof Blob
          msgevent += ':binary'
          content = e.data
        else
          content = {}
          try
            content = JSON.parse e.data
            content = content[content_key] if opts.content_key

          if content[ws.PING]
            socket.conn.send JSON.stringify _.pick content, ws.PING

        vent.trigger msgevent, content

    socket.conn

  ws.getSocket = (name) -> ws._sockets[name]?.conn

  ws.close = (name) ->
    socket = ws._sockets[name]
    if socket
      clearTimeout socket._reconnect_timer
      if socket.conn.readyState is WebSocket.CLOSED
        delete ws._sockets[name]
      else
        socket.conn.close 1000, 'OK'

  # exponential backoff algo based on attempts
  ws.getReconnectTimeout = (cnt) ->
    max = (Math.pow(2, cnt) - 1) * 1000
    max = ws.MAX_RETRY_MS if max > ws.MAX_RETRY_MS
    return parseInt Math.random() * max

  ws
