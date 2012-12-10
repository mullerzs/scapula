define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  lang = require 'lang'
  vent = require 'vent'
  utils = require 'utils'

  class Router extends Backbone.Router
    initialize: ->
      @viewRoutes =
        # Sample login route
        'Login' : route: 'login'

      createRoute = (view, parnames) ->
        ->
          opts = {}
          opts[parname] = arguments[i] for parname, i in parnames if parnames
          vent.trigger 'view:load', view, opts

      for view of @viewRoutes
        val = @viewRoutes[view]
        val.callback = createRoute view, val.parnames
        @route val.route, view.toLowerCase(), val.callback

      vent.bind 'route', @callRoute

    callRoute: (dst) =>
      dst = (dst || '').replace /^\//, ''
      for view of @viewRoutes
        val = @viewRoutes[view]
        route = val.route
        if dst is route || route instanceof RegExp && pars = dst.match route
          callback = val.callback
          break

      if callback
        callback.apply @, (pars || []).slice(1)
      else
        vent.trigger 'view:load', 'Error', msg: lang.error_req

  new Router()
