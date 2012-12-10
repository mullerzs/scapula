define (require) ->
  lang = require 'i18n!nls/lang'
  langpar = require 'i18n!nls/langpar'
  utils = require 'utils'

  preproc = {}
  ivars = {}

  for varname of langpar
    obj = utils.interpolate langpar[varname],
      keepVar : true
      verbose : true
    preproc[varname] = obj.res
    if obj.ivars
      for v in obj.ivars
        ivars[v] ?= []
        ivars[v].push varname

  preproc['__ivars'] = ivars

  _.extend {}, lang, preproc
