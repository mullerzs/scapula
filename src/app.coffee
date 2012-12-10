define (require) ->
  Backbone = require 'backbone'
  Router = require 'router'
  vent = require 'vent'
  lang = require 'lang'
  utils = require 'utils'

  # NOTE: require the desired sync module here
  require 'restsync'
  #require 'localsync'

  require 'jquerynt'

  app = {}

  app.initialize = ->
    # console.log JSON.stringify window.ntConfig

    pushState = !!(window.history && window.history.pushState)
    Backbone.history.start
      pushState : pushState
      root      : utils.getConfig 'base'
      silent    : true

    # bypass "a" html tags with no reasonable href
    $(document).on 'click', 'a', (e) ->
      href = $(@).attr('href')
      e.preventDefault() if !href || href is '#'

    # sanitize formatted content when pasting into conted
    $(document).on 'paste', '[contenteditable=true]', (e) ->
      $tgt = $(e.target).closest '[contenteditable=true]'
      setTimeout ->
        $tgt.html $tgt.text()
      , 10

    $(document).on 'focus', '[contenteditable=true]', (e) ->
      $(e.target).ntSelectElementContents()

    vent.bind 'ajax:unauth', app.unauth
    vent.bind 'ajax:error', app.ajaxError
    vent.bind 'api:error', app.apiError
    vent.bind 'view:load', app.viewLoad

    dst = utils.getStatus('route')
    if !dst
      loc = Backbone.history.fragment unless pushState
      dst = loc || 'login'

    # console.log 'Initial route: ' + dst

    dst = 'error' if parseInt(utils.getStatus 'http_status') is 404
    Router.callRoute dst

  app.viewLoad = (view, opts) ->
    opts ?= {}
    vent.trigger 'alert:hide'

    app.view.close() if app.view
    # console.log 'Loading view: ' + view
    requireView = (View) =>
      app.view = new View opts

      app.view.bindTo app.view, 'render', =>
        if !app.view.noWell
          addh = 0
          for cssdef in [ 'padding-top', 'padding-bottom', 'margin-top', 'margin-bottom' ]
            addh += parseInt app.view.$el.css cssdef

          debounceResize = _.debounce (e) =>
            app.view.adjustHeight $(window).height() - addh, init: true
          , 50

          $(window).on('resize', debounceResize).trigger 'resize'
        else
          $(window).off 'resize'
      , @

      # TODO: cache fetch
      viewObj = app.view.model || app.view.collection
      if viewObj && !app.view.noFetch
        viewObj.fetch()
      else
        app.view.render()

      statusMsg = utils.getStatus 'msg'
      if statusMsg && statusMsg.desc
        vent.trigger 'alert:show', statusMsg.desc, statusMsg
      else if opts.alertMsg
        vent.trigger 'alert:show', opts.alertMsg, opts.alertOpts

      if view in _.keys(Router.viewRoutes) || view is 'Event'
        url = '/' + view.toLowerCase()

        Backbone.history.navigate url

    # NOTE: require string literals are needed for optimizer!
    switch view
      when 'Login'       then require [ 'views/Login' ], requireView
      when 'Error'       then require [ 'views/Error' ], requireView

  app.unauth = (reason) ->
    unless reason in [ 'error_sestimeout', 'error_unauth' ]
      reason = 'error_unauth'
    reason = reason.replace /^error_/, ''

    loc = Backbone.history.fragment
    loc = '/' + loc unless loc.match /^\//

    href = '/sestimeout'

    document.location.href = href + loc + '?reason=' + reason

  app.ajaxError = (error) ->
    return unless _.isArray error
    vent.trigger 'alert:show', err.code for err in error

  app.apiError = (method) ->
    # TODO: more verbose + lang message?
    vent.trigger 'alert:show', 'API error: ' + method

  app
