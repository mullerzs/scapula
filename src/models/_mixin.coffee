define (require) ->
  mixin = {}
  utils = require 'utils'

  mixin.dateUtils =
    incDate: (flds, addValues, opts) ->
      return unless flds && _.isObject addValues
      opts ?= 0
      flds = [ flds ] unless _.isArray flds
      attrs = {}

      for fld in flds
        val = @get fld
        val = opts.initVal if !val? && opts.initVal
        attrs[fld] = utils.dateAdd val, addValues, opts if val

      @[ if opts.save then 'save' else 'set' ](attrs)

  mixin
