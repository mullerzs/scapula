define (require) ->
  Base = require 'baseviews'

  # Mock view
  class Login extends Base.View
    render: ->
      @$el.html 'Scapula is working!'
