define (require) ->
  _ = require 'underscore'
  utils = require 'scapula-utils'
  config_utils = require 'config-utils'
  Handlebars = require 'handlebars'

  module = {}

  module.interpolate = (str, langobj = {}, opts = {}) ->
    return str unless _.isString str
    skip = opts.skip ? []
    skip = [ skip ] unless _.isArray skip
    ivars = []

    res = str.replace /#\{(.*?)\}/g, (whole, expr) ->
      if expr.match /^lang\./
        ret = langobj[expr.replace /^lang\./, ''] unless 'lang' in skip
      else if expr.match /^cfg\./
        unless 'cfg' in skip
          ret = config_utils.getConfig expr.replace /^cfg\./, ''
      else
        plexpr = expr.match /^(\S+)\s+(.+)$/
        if plexpr
          expr = plexpr[1]
          items = plexpr[2].split '|'
          num = parseFloat opts.vars?[expr]
          # TODO: support languages having more complex pluralization
          descr = if _.isFinite(num) && items.length > 1 && num != 1
            items[1]
          else
            items[0]

        ret = opts.vars?[expr]
        ret += ' ' + descr if ret? && descr?
        ivars.push expr if opts.verbose

      if ret?
        ret = ret.toString() if _.isNumber ret
        ret = '' unless _.isString ret
      else if opts.keepVar
        ret = whole

      ret

    if opts.verbose then { res: res, ivars: ivars } else res

  module.preprocess = (langobj) ->
    preproc = {}
    ivars = {}

    for varname, val of langobj
      continue unless _.isString val
      obj = module.interpolate val, langobj,
        keepVar : true
        verbose : true
        skip    : 'cfg'
      preproc[varname] = obj.res
      if obj.ivars
        for v in obj.ivars
          ivars[v] ?= []
          ivars[v].push varname

    preproc['__ivars'] = ivars

    _.extend {}, langobj, preproc

  module.isHtmlKey = (key) -> key?.match /_html$/

  module.getLang = (key, langobj, opts) ->
    opts ?= {}
    langobj ?= {}

    check = [ key ]
    check.push key + '_html' if key && !module.isHtmlKey key

    if check && opts.default
      check.push opts.default
      check.push opts.default + '_html' unless module.isHtmlKey opts.default

    for k in check
      break if str?
      str = langobj[k]
      key = k

    if str
      if opts.vars || str.match /#\{cfg\..+?\}/
        str = module.interpolate str, langobj,
          vars: opts.vars, keepVar: !!opts.htmlVars

      if (opts.encode ? opts.hbs) && !module.isHtmlKey key
        str = utils.encodeHtml str

      if opts.htmlVars
        str = module.interpolate str, langobj, vars: opts.htmlVars

      str = new Handlebars.SafeString str if opts.hbs

    str

  module
