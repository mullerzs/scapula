define (require) ->
  Base = require 'baseviews'
  utils = require 'utils'
  lang = require 'lang'
  vent = require 'vent'

  class AlertView extends Base.View
    el: '#alert'

    initialize: ->
      @$hdr = @$el.find('h4')
      @$msg = @$el.find('div')
      @timeout = 10000
      vent.bind 'alert:show', @show
      vent.bind 'alert:hide', @hide

    initDomEvents: =>
      @addDomEvent
        'click .close' : 'hide'

    hide: =>
      clearTimeout @hideTo
      @$el.fadeOut() if @$el.is ':visible'

    show: (msg, opts) =>
      @hide()
      opts ?= {}
      top = opts.offset || 10
      @$el.css 'top', top + 'px'
      type = opts.type
      hdr = opts.hdr
      timeout = opts.timeout || @timeout

      cname = 'alert'

      if type && type.match /^(error|warn|info|success)$/
        if hdr
          if _.isString(hdr) && lang[hdr]
            @$hdr.html utils.encodeHtml lang[hdr]
          else
            @$hdr.html lang[type]
        cname += ' alert-' + type if type isnt 'warn'
      else
        hdr = undefined
        @$hdr.empty()
        cname += ' alert-error'

      @$hdr[ if hdr then 'show' else 'hide' ]()

      cname += ' large' if opts.large

      @$el.get(0).className = cname

      msg = lang.error_internal unless msg?
      msg = lang[msg] if lang[msg]
      @$msg.html utils.encodeHtml msg

      clearTimeout @showTo
      @showTo = setTimeout =>
        @$el.fadeIn()
      , 10

      @hideTo = setTimeout =>
        @hide()
      , timeout

  # AlertView is a singleton!
  # el: #alert is the part of the index.html
  new AlertView()
