define (require) ->
  lang = require 'i18n!nls/lang'
  utils = require 'utils'

  preproc = {}
  ivars = {}

  for varname, val of lang
    continue unless val.match /\#\{(cfg|lang)\./
    obj = utils.interpolate val,
      keepVar : true
      verbose : true
    preproc[varname] = obj.res
    if obj.ivars
      for v in obj.ivars
        ivars[v] ?= []
        ivars[v].push varname

  preproc['__ivars'] = ivars

  _.extend {}, lang, preproc
