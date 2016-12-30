define (require) ->
  _ = require 'underscore'

  utils = {}

  utils.getVarSrc = (src) ->
    if src is 'config' then window.ntConfig else window.ntStatus

  utils.getVar = (src, varname, opts) ->
    src = utils.getVarSrc src
    if varname? && _.isObject src
      varname = varname.toString().split '.'
      ret = src
      for i in [0 .. varname.length - 1]
        if !_.isObject ret
          ret = undefined
          break
        ret = ret[varname[i]]

      if !opts?.ref
        if _.isArray ret
          ret = _.extend [], ret
        else if _.isObject(ret) && !_.isFunction ret
          ret = _.extend {}, ret

    ret

  utils.getConfig = (varname, opts) ->
    utils.getVar 'config', varname, opts

  utils.getStatus = (varname, opts) ->
    ret = utils.getVar 'status', varname, opts
    utils.delStatus varname
    ret

  utils.setVar = (src, varname, value) ->
    if _.isObject varname
      obj = varname
    else
      (obj = {})[varname] = value

    src = utils.getVarSrc src
    _.extend src, obj

  utils.setConfig = (varname, value) ->
    utils.setVar 'config', varname, value

  utils.setStatus = (varname, value) ->
    utils.setVar 'status', varname, value

  utils.delStatus = (varname) ->
    src = utils.getVarSrc 'status'
    delete src[varname] if varname?
