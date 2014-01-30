define (require) ->
  Backbone = require 'backbone'
  Router = require 'Router'
  routes = require 'routes'
  vent = require 'vent'
  utils = require 'utils'

  # NOTE: require the desired sync module here
  require 'restsync'

  app = {}

  app.initialize = ->
    app.router = new Router viewRoutes: routes

    Backbone.history.start
      pushState : true
      root      : utils.getConfig 'base'
      silent    : true

    ### bypass "a" html tags with no reasonable href
    $(document).on 'click', 'a', (e) ->
      href = $(@).attr('href')
      e.preventDefault() if !href || href is '#'
    ###

    vent.on 'ajax:unauth', app.unauth
    vent.on 'ajax:error', app.ajaxError
    vent.on 'view:load', app.viewLoad

    dst = utils.getStatus('route') || 'login'

    # console.log 'Initial route: ' + dst

    app.router.callRoute dst

  app.viewLoad = (view, opts) ->
    opts ?= {}

    if app.view
      opts.login = app.view.getClass() is 'Login'
      app.view.close()
    else
      firstLoad = true

    # console.log 'Loading view: ' + view
    requireView = (View) =>
      app.view = new View _.extend el: '#container', opts

      ### resize?
      app.view.$el.css 'height', 'auto'
      app.view.listenTo app.view, 'render', =>
        if app.view.autoResize
          debounceResize = _.debounce (e) =>
            app.view.adjustHeight init: true
          , 50

          $(window).on('resize', debounceResize).trigger 'resize'
        else
          $(window).off 'resize'
      ###

      viewObj = app.view.model || app.view.collection
      if !opts.model && !app.view.noFetch && viewObj
        if app.view.fetch then app.view.fetch() else viewObj.fetch()
      else
        app.view.render()

      ### messages?
      statusMsg = utils.getStatus 'msg'
      if statusMsg && statusMsg.desc
        vent.trigger 'alert:show', statusMsg.desc, statusMsg
      else if opts.alertMsg
        vent.trigger 'alert:show', opts.alertMsg, opts.alertOpts
      ###

      if view of app.router.viewRoutes
        url = view.toLowerCase()
        navopts = {} # manage replace state
        Backbone.history.navigate "/#{url}", navopts

    # NOTE: require string literals are needed for optimizer!
    switch view
      when 'Login' then require [ 'views/Login' ], requireView
      when 'Error' then require [ 'views/Error' ], requireView

  app.unauth = (reason) ->
    # TODO: handle unauthorized user interactions

  app.ajaxError = (error) ->
    # TODO: handle global ajax errors

  app
