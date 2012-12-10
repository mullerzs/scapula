define (require) ->
  _ = require 'underscore'
  # NOTE: currently no langpar support for utils (langutils?)
  lang = require 'i18n!nls/lang'

  require 'date'
  require 'moment'

  utils =
    REG_EMAIL      : '[-_a-z0-9]+(\\.[-_a-z0-9]+)*@[-a-z0-9]+(\\.[-a-z0-9]+)*\\.[a-z]{2,6}'
    FMT_DT_ISO     : 'YYYY-MM-DD HH:mm:ss'
    FMT_DT_ISO8601 : 'YYYY-MM-DDTHH:mm:ss'

  utils.xor = (a, b) ->
    (a || b) && !(a && b)

  utils.isInternalAttr = (name) ->
    name && name.toString().match /^_/

  utils.extendMethod = (to, from, methodName) ->
    if _.isFunction(to[methodName]) && _.isFunction(from[methodName])
      old = to[methodName]
      to[methodName] = ->
        oldReturn = old.apply @, arguments
        from[methodName].apply @, arguments
        oldReturn

  utils.mixin = (mixins..., classRef) ->
    to = classRef::
    for mixin in mixins
      for method of mixin
        utils.extendMethod to, mixin, method
      _.defaults to, mixin
      _.defaults to.events, mixin.events
    classRef

  utils.getProp = (object, prop) ->
    return null unless object && object[prop]
    if _.isFunction object[prop] then object[prop]() else object[prop]

  utils.getObjProp = (obj, prop) ->
    if obj instanceof Backbone.Model then obj.get(prop) else obj[prop]

  utils.loadCss = (fname) ->
    ex = 0
    $('head link').each ->
      if $(@).attr('href') == fname
        ex = 1
        return

    $('head').append('<link rel="stylesheet" type="text/css" href="' + fname + '" />') unless ex

  utils.chkEmail = (str) ->
    re_email = new RegExp "^#{utils.REG_EMAIL}$", 'i'
    if str? && str.toString().match re_email
      str
    else
      undefined

  utils.encodeHtml = (str) ->
    return str unless str?
    str = str.toString()
    str.replace(/&/g, '&amp;')
       .replace(/</g, '&lt;')
       .replace(/>/g, '&gt;')
       .replace(/\n$/, '<br/>&nbsp;')
       .replace(/\n/g, '<br/>')
       .replace /\s{2,}/g, (space) ->
         len = space.length
         res = ''
         res += '&nbsp;' for num in [1..len]
         res

  utils.decodeHtml = (str) ->
    return str unless str?
    str = str.toString()
    $.trim str.replace(/\s+/g, ' ')
              .replace(/&lt;/g, '<')
              .replace(/&gt;/g, '>')
              .replace(/&nbsp;/g, ' ')
              .replace(/&amp;/g, '&')
              .replace(/<br\s*\/?>$/, '')
              .replace(/<br\s*\/?>/g, "\n")

  utils.extractKeywords = (str) ->
    ret = []
    str = $.trim str.toString() if str?
    if str
      qre = /\"\s*(.+?)\s*\"/g
      while kw = qre.exec str
        str = str.replace kw[1], ''
        ret.push kw[1]

      str = str.replace /\"\s*\"/g, ''
      str = $.trim str

      ret = ret.concat str.split /\s+/ if !ret.length || str?.length

    ret

  utils.throwError = (desc,name) ->
    name = 'Error' unless name?
    desc = 'unknown' unless desc?
    err = new Error desc
    err.name = name
    throw err

  utils.cookie = (key, value, options) ->
    if arguments.length > 1 && (!/Object/.test(Object.prototype.toString.call(value)) || !value?)
      options = $.extend {}, options

      if !value?
        options.expires = -1

      if typeof options.expires == 'number'
        days = options.expires
        t = options.expires = new Date()
        t.setDate t.getDate() + days

      value = String value

      return document.cookie = [
        encodeURIComponent(key)
        '='
        if options.raw then value else encodeURIComponent(value)
        if options.expires then '; expires=' + options.expires.toUTCString() else ''
        if options.path then '; path=' + options.path else ''
        if options.domain then '; domain=' + options.domain else ''
        if options.secure then '; secure' else ''
      ].join ''

    options = value || {}
    decode = if options.raw then (s) -> return s else decodeURIComponent

    pairs = document.cookie.split '; '

    i = 0
    pair = undefined

    while pair = pairs[i] && pairs[i].split /\=(.+)?/
      return decode(pair[1] || '') if decode(pair[0]) is key
      i++

    return null

  utils.getVarSrc = (src) ->
    if src is 'config' then window.ntConfig else window.ntStatus

  utils.getVar = (src, varname, opts) ->
    src = utils.getVarSrc src
    if varname?
      ret = src[varname]
      if !opts?.ref
        if _.isArray ret
          ret = _.extend [], ret
        else if _.isObject ret
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
      obj = {}
      obj[varname] = value

    src = utils.getVarSrc src
    _.extend src, obj

  utils.setConfig = (varname, value) ->
    utils.setVar 'config', varname, value

  utils.setStatus = (varname, value) ->
    utils.setVar 'status', varname, value

  utils.delStatus = (varname) ->
    src = utils.getVarSrc 'status'
    delete src[varname] if varname?

  utils.quotemeta = (str) ->
    str ?= ''
    str.replace /([\.\\\+\*\?\[\^\]\$\(\)])/g, '\\$1'

  utils.interpolate = (str, opts) ->
    return str unless _.isString str
    opts ?= {}
    ivars = []

    # NOTE: tag wrap turns on encoding automatically!
    opts.encode = true if str.match /%\{(.*?)\}/

    str = utils.encodeHtml str if opts.encode

    # NOTE: creates span tag from %{[class]}...%/{}
    res = str.replace /%\{(.*?)\}/g, (whole, expr) ->
      ret = '<span'
      ret += ' class="' + expr + '"' if expr
      ret += '>'
    res = res.replace /%\/\{\}/g, '</span>'

    res = res.replace /#\{(.*?)\}/g, (whole, expr) ->
      if expr.match /^lang\./
        ret = lang[expr.replace /^lang\./, '']
      else if expr.match /^cfg\./
        ret = utils.getConfig(expr.replace /^cfg\./, '')
      else
        ret = opts.vars?[expr]
        ivars.push expr if opts.verbose

      if ret?
        ret = ret.toString() if _.isNumber ret
        ret = '' unless _.isString ret
        ret = utils.encodeHtml ret if opts.encode
      else if opts.keepVar
        ret = whole

      ret

    if opts.verbose then { res: res, ivars: ivars } else res

  utils.sort = (a, b, props, opts) ->
    ret = 0
    if props
      props = [ props ] unless _.isArray props
      for prop in props
        cmp = []
        for obj in [a, b]
          if _.isArray prop
            for altprop in prop
              tmp = utils.getObjProp obj, altprop
              break if tmp?
          else
            tmp = utils.getObjProp obj, prop

          if opts?.natural && _.isString tmp
            tmp = tmp.replace(/(\d+)/g, "0000000000$1").replace(/0*(\d{10,})/g, "$1").replace(/@/g,' ')
            tmp = tmp.toLowerCase()
          tmp ?= ''
          cmp.push tmp

        if cmp[0] < cmp[1]
          ret = -1
        else if cmp[0] > cmp[1]
          ret = 1
        break if ret
    else
      if a < b
        ret = -1
      else if a > b
        ret = 1

    ret *= -1 if opts?.desc
    ret

  utils.hexColorToRGBSum = (h) ->
    # TODO: 3 length hex
    red = parseInt h.substring(0,2), 16
    green = parseInt h.substring(2,4), 16
    blue = parseInt h.substring(4,6), 16

    return (red << 16) + (green << 8) + blue

  utils.isLightColor = (color) ->
    if utils.hexColorToRGBSum(color) < 10000000 then true else false

  utils.colorScale = (val, opts) ->
    opts ?= {}

    val = parseFloat val
    if _.isFinite val
      inverse = true if val < 0
      val = Math.abs val
      max = if inverse then Math.abs(opts.min) else opts.max

      if _.isNumber(max) && max && val <= max
        if opts.logarithmic
          val = Math.log(val + 1)
          max = Math.log(max + 1)

        ret =
          'background-color' : if inverse then 'red' else 'green'
          'opacity'          : val / max

        if opts.string
          str = ''
          for k of ret
            str += ';' if str
            str += k + ': ' + ret[k]
          ret = str

    ret

  utils.isValidDbDate = (str) ->
    str && str.toString().match /^\d{4}(-\d{2}){2}\s+\d{2}(:\d{2}){2}$/

  utils.parseDbDate = (str) ->
    if utils.isValidDbDate str
      moment.utc(str, utils.FMT_DT_ISO).local()
    else
      str

  utils.dbDateToIso8601 = (str) ->
    m = utils.parseDbDate str
    if _.isObject(m) then m.format(utils.FMT_DT_ISO8601) else str

  utils.isValidIso8601Date = (str) ->
    str && str.toString().match /^\d{4}(-\d{2}){2}T\d{2}(:\d{2}){2}$/

  utils.iso8601ToDbDate = (str) ->
    if utils.isValidIso8601Date str
      moment(str).utc().format utils.FMT_DT_ISO
    else
      str

  utils.parseDate = (dm, opts) ->
    format = opts?.format
    if format
      ret = moment dm, format
    else
      if _.isString dm
        dm = utils.parseDbDate dm
        dm = Date.parse dm unless _.isObject dm

      ret = moment dm

    ret

  utils.parseTime = (dm, opts) ->
    dt = dm if _.isString dm
    ret = utils.parseDate dm, opts

    if dt && !utils.isValidTime ret
      ret = moment dt, [
        'hh:mm', 'h:mma', 'hh:mma', 'hh:mm a',
        'h:mm a', 'ha', 'h a', 'hh a', 'h:mm'
      ]

    ret

  utils.formatDate = (dm,opts) ->
    m = if dm? && _.isString dm
      utils.parseDate dm
    else
      dm

    if m
      if opts?.time then utils._formatDateTime m else utils._formatDate m
    else
      ''

  utils.formatDateTime = (dm,opts) ->
    utils.formatDate dm, _.extend opts || {}, time: true

  utils.formatTime = (dm,opts) ->
    m = if dm? && _.isString dm
      utils.parseTime dm
    else
      dm

    if m
      utils._formatTime m
    else
      ''

  utils._formatDate = (m) ->
    m.format(utils.getConfig('dateformat') || 'D MMM YYYY')

  utils._formatTime = (m) ->
    m.format(utils.getConfig('timeformat') || 'h:mm a')

  utils._formatDateTime = (m) ->
    # TODO: datetime format
    utils._formatDate(m) + ' ' + utils._formatTime(m)

  utils.formatTextMonth = (dm) ->
    m = moment dm
    m.format(utils.getConfig('monthformat') || 'MMMM YYYY')

  utils.isValidDate = (m) ->
    m? && m.toDate().toString() != 'Invalid Date' && 2000 < m.year() < 2099

  utils.isValidTime = (m) ->
    m? && (d = m.toDate()).toString() != 'Invalid Date' &&
      (d.getHours() != 0 || d.getMinutes() != 0 || d.getSeconds() != 0)

  utils.isDateBetween = (sdate, edate, date) ->
    date = new Date() unless date?
    sdate = date unless sdate?
    edate = date unless edate?
    sdate <= date <= edate

  utils.splitIsoDateTime = (dt) ->
    if _.isString(dt) then dt.split /[\s+T]/ else []

  utils.joinIsoDateTime = (dtarr, sep) ->
    sep = 'T' unless sep
    if _.isArray(dtarr) then dtarr.join(sep) else ''

  utils.getIsoDateTime = (opts) ->
    opts ?= {}
    d = new Date()
    opts.year ?= d.getFullYear()
    opts.month ?= d.getMonth()
    opts.day ?= d.getDate()
    opts.hour ?= d.getHours()
    opts.min ?= d.getMinutes()
    opts.sec ?= d.getSeconds()

    d = new Date(opts.year, opts.month, opts.day, opts.hour, opts.min, opts.sec)

    m = moment(d)
    m.format utils.FMT_DT_ISO8601

  utils.getIsoDate = (opts) ->
    dt = utils.getIsoDateTime opts
    dt = utils.splitIsoDateTime dt
    dt[0]

  utils.getIsoYearMonth = (y, m) ->
    d = if y && m then new Date(y, m, 0) else new Date()
    m = moment(d)
    m.format 'YYYY-MM'

  utils.extractIsoDateTime = (opts) ->
    opts ?= {}
    dt = opts.dt || utils.getIsoDateTime()
    dtarr = utils.splitIsoDateTime dt
    if opts.date
      dtarr[0]
    else if opts.time
      dtarr[1]
    else
      dtarr

  utils.dateAdd = (date, addValues, opts) ->
    m = utils.parseDate date
    for prop of addValues
      m.add prop, addValues[prop]
    fmt = opts?.format || utils.FMT_DT_ISO8601
    m.format fmt

  utils.dateDiff = (date, prop, base) ->
    base = moment() unless base
    date = moment date
    date.diff base, prop

  utils.updateIsoDateTime = (dt, opts) ->
    fmtarr = utils.splitIsoDateTime utils.FMT_DT_ISO8601
    date = opts?.date
    date = moment(date).format fmtarr[0] if _.isObject date
    time = opts?.time
    time = moment(time).format fmtarr[1] if _.isObject time
    dtarr = utils.extractIsoDateTime dt: dt
    dtarr[0] = date if date
    dtarr[1] = time if time

    utils.joinIsoDateTime dtarr

  utils.formatFileSize = (size, opts) ->
    opts ?= {}
    size = parseFloat size
    if _.isFinite size
      size /= 1024 * 1024
      size = if opts.decDigits
        size.toFixed(opts.decDigits)
      else
        Math.round(size)

      size += 'M'
    else
      size = lang.na

    size

  utils.formatPct = (pct) ->
    pct = parseFloat pct unless _.isNumber pct
    if _.isFinite pct
      pct = Math.round((pct * 100).toFixed(2)) + '%'
    else
      # TODO: common lang na for all?
      pct = lang.na_pct

    pct

  utils.mean = (arr) ->
    arrLen = arr?.length
    if arrLen > 1
      mean = arr.reduce (a, b) -> a + b
      mean /= arrLen
    else if arrLen > 0
      mean = arr[0]
    mean

  utils.extractEmails = (str) ->
    re_email = new RegExp "(?:([^@]+)\s*<#{utils.REG_EMAIL}>|#{utils.REG_EMAIL})", 'gi'
    emails_matched = str?.toString().match re_email

    emails = []
    _.each emails_matched, (user_email) ->
      name = null
      email = user_email
      if user_email.match /</
        tmp = user_email.split /</
        name = $.trim tmp[0]
        email = $.trim tmp[1]

      email = email.replace />/, ''

      user = email: email
      user.name = name if name

      emails.push user

    emails

  utils
