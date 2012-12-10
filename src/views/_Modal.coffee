define (require) ->
  Base = require 'baseviews'
  utils = require 'utils'

  require 'bootstrap'

  class ModalView extends Base.ParentView
    className: 'nt-modal modal hide fade'

    initDomEvents: =>
      @addDomEvent
        'hidden' : @hidden

    hidden: =>
      @$backdrop.css 'z-index', 1040 if @$backdrop && !@keepBackdrop
      @close()

    render: =>
      super

      # handle modal in modal
      @$backdrop = $('body > .modal-backdrop')
      @$backdrop = null unless @$backdrop.get(0)

      @$el.modal
        keyboard : false
        backdrop : if @$backdrop then false else 'static'

      if @$backdrop
        @$backdrop.css 'z-index', 1051
        @$el.css 'z-index', 1060
