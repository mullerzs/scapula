define (require) ->
  Handlebars = require 'handlebars'
  utils = require 'utils'

  Handlebars.registerHelper 'lc', (str) ->
    str.toString().toLowerCase()

  Handlebars.registerHelper 'intpol', ->
    args = [].slice.call arguments
    str = args.shift()
    names = utils.extractVars str
    vars = {}
    vars[name] = args[i] for name, i in names
    utils.interpolate str, vars: vars
