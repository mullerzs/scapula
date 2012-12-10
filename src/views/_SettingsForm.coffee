define (require) ->
  Base = require 'baseviews'
  lang = require 'lang'
  utils = require 'utils'
  alert = require 'views/alert'

  require 'jquerynt'

  class SettingsForm extends Base.ParentView
    initEvents: =>
      @bindTo @model, 'error', @errorInput, @

    render: =>
      super
      @$('.nt-input-inspect').ntContentSpy()

    errorInput: (model, err) =>
      for id of @fldElem
        flderr = err[@fldElem[id]]
        if flderr
          @toggleInputMsg id, 'err', flderr
          @toggleInputError id, true if document.activeElement isnt $('#' + id).get(0)

    toggleInputMsg: (id, type, msg, tooltip) =>
      $msg = @$('#' + id + 'Msg')
      if (!type || type isnt 'ok') && !msg
        $msg.addClass 'hide'
      else
        icon = if type is 'ok'
          'icon-ok'
        else if type is 'wrn'
          'icon-exclamation-sign'
        else
          'icon-remove error'
        $msg.find('i').get(0).className = icon
        msg = lang[msg] if lang[msg]
        $msg.find('span, div').html if msg then utils.encodeHtml msg else ''
        $msg.removeClass 'hide'
        if tooltip
          $msg.attr 'data-original-title', utils.encodeHtml tooltip
          $msg.tooltip()
        else
          $msg.removeAttr 'data-original-title'

    toggleInputError: (id, err) =>
      @$('#' + id).closest('.control-group')[ if err then 'addClass' else 'removeClass' ]('error')

    showAlert: (msg) =>
      # alert.show msg, offset: @$el.offset().top + 5
      alert.show msg

    hidden: =>
      alert.hide()
      super

