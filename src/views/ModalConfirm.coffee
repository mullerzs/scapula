define (require) ->
  ModalMsgView = require 'views/_ModalMsg'
  tpl = require 'text!tpls/modal_confirm.html'

  class ModalConfirmView extends ModalMsgView
    initialize: =>
      @template = tpl

