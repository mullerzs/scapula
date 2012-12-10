define (require) ->
  ModalView = require 'views/_Modal'

  class ModalMsgView extends ModalView
    constructor: ->
      super
      @$el.addClass 'nt-msg'

    initTplVars: =>
      @addTplVar
        msg: @options?.msg

    initDomEvents: =>
      super
      @addDomEvent
        'click .nt-btn-ok' : @okClick

    hidden: =>
      @trigger 'okClick', @okOpts if @okOpts
      super

    okClick: =>
      @okOpts ?= {}
      @keepBackdrop = @options?.keepBackdrop
      @$el.modal 'hide'
      false

