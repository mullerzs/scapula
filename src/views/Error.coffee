define (require) ->
  Base = require 'baseviews'
  tpl = require 'text!tpls/error.html'
  lang = require 'lang'
  vent = require 'vent'
  utils = require 'utils'

  class ErrorView extends Base.View
    el: '#container'

    initialize: ->
      @template = tpl

      @noWell = true

    initTplVars: =>
      @addTplVar msg: @options?.msg || lang.error_internal

    initDomEvents: =>
      @addDomEvent
        'click #login' : 'login'

    login: =>
      utils.delStatus 'initpage'
      vent.trigger 'view:load', 'Login'
