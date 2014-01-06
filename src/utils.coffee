define (require) ->
  _ = require 'underscore'
  vent = require 'vent'
  lang = require 'i18n!nls/lang'
  moment = require 'moment'

  require 'jquerynt'
  require 'base64'
  require 'date'

  utils =
    REG_EMAIL      : '[-_a-z0-9]+(\\.[-_a-z0-9]+)*@[-a-z0-9]+(\\.[-a-z0-9]+)' +
                     '*\\.[a-z]{2,6}'
    REG_DT_ISO     : '\\d{4}(-\\d{2}){2}\\s+\\d{2}(:\\d{2}){2}'
    REG_DT_ISO8601 : '\\d{4}(-\\d{2}){2}T\\d{2}(:\\d{2}){2}'
    FMT_DT_ISO     : 'YYYY-MM-DD HH:mm:ss'
    FMT_DT_ISO8601 : 'YYYY-MM-DDTHH:mm:ss'

  utils.xor = (a, b) ->
    (a || b) && !(a && b)

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

  utils.getProp = (obj, prop, opts) ->
    if opts?.attr && obj instanceof Backbone.Model
      obj.get prop
    else
      _.result obj, prop

  # obj, srcobj, props as args || props array
  utils.adoptProps = ->
    args = [].slice.call arguments
    obj = args.shift()
    srcobj = args.shift()
    if _.isObject(obj) && _.isObject(srcobj)
      keys = if _.isArray args[0] then args[0] else args
      _.extend obj, _.pick srcobj, keys

  utils._chkRegExp = (str, re_name) ->
    re = new RegExp "^#{utils[re_name]}$", 'i'
    if str? && str.toString().match re
      str
    else
      undefined

  utils.chkEmail = (str) ->
    utils._chkRegExp str, 'REG_EMAIL'

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

  # TODO: advanced string based ranking
  # Ranking algorithm rules:
  # 1. For the first element choose the 2. character
  # 2. When appending try to choose the next character in proportion to the last
  # 3. When inserting try to calculate the median
  #
  # A, B, C, D, E
  # (Q) B
  # (Q) C   <--- before C, insert: BC
  # (Q) D
  # (Q) E
  # (Q) EC  <--- before EC, insert: EB
  # (Q) ED
  # (Q) EE  <--- before EE, insert: EDC
  # (Q) EEC
  # (Q) ...

  utils.calcRank = (prev,next) ->
    if prev? && !_.isNumber(prev) || next? && !_.isNumber(next)
      utils.throwError 'Invalid parameters for calcRank'

    if prev? && !next?
      ret = prev + 1
    else if !prev? && next
      ret = next / 2
    else if prev? && next?
      ret = (next + prev) / 2
    else
      ret = 1

    ret

  utils.numToLetters = (num) ->
    num = parseInt num
    return unless _.isFinite num

    ret = ''
    while num > 0
      mod = (num - 1) % 26
      ret = String.fromCharCode(65 + mod) + ret
      num = parseInt((num - mod) / 26)

    ret

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

  utils.decodeCookie = (key) ->
    val = utils.cookie key
    Base64.decode val if val?

  utils.getVarSrc = (src) ->
    if src is 'config' then window.ntConfig else window.ntStatus

  utils.getVar = (src, varname, opts) ->
    src = utils.getVarSrc src
    if varname? && _.isObject src
      varname = varname.toString().split '.'
      ret = src
      for i in [0 .. varname.length - 1]
        ret = ret[varname[i]]

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

  utils.extractVars = (str) ->
    vars = []
    re = /#\{([^\s\}]+).*?\}/g
    while match = re.exec str
      vars.push match[1]
    vars

  utils.interpolate = (str, opts) ->
    return str unless _.isString str
    opts ?= {}
    ivars = []

    res = str.replace /#\{(.*?)\}/g, (whole, expr) ->
      if expr.match /^lang\./
        ret = lang[expr.replace /^lang\./, '']
      else if expr.match /^cfg\./
        ret = utils.getConfig(expr.replace /^cfg\./, '')
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

  utils._sort = (a, b, opts) ->
    ret = if b? && (!a? || a < b)
      -1
    else if a? && (!b? || a > b)
      1

    ret *= -1 if ret && opts?.desc
    ret

  utils.sort = (a, b, props, opts) ->
    opts ?= {}
    ret = 0

    if props
      props = [ props ] unless _.isArray props
      for prop in props
        cmp = []
        pname = if _.isObject(prop) then prop.name else prop
        popts = if _.isObject(prop) then _.clone(prop.opts) else {}
        _.defaults popts, opts, attr: true
        for obj in [a, b]
          if _.isArray pname
            for altpname in pname
              tmp = utils.getProp obj, altpname, popts
              break if tmp?
          else
            tmp = utils.getProp obj, pname, popts

          if popts.natural && _.isString tmp
            tmp = tmp.replace(/(\d+)/g, "0000000000$1")
              .replace(/0*(\d{10,})/g, "$1").replace(/@/g,' ')
            tmp = tmp.toLowerCase()
          cmp.push tmp

        ret = utils._sort.apply @, cmp.concat(popts)
        break if ret
    else
      ret = utils._sort a, b, opts

    ret

  utils.processByFuncs = (val, funcs, ctx) ->
    return val unless funcs?

    funcs = [ funcs ] unless _.isArray funcs
    for func in funcs
      f = if _.isFunction(func)
        func
      else if _.isFunction(utils[func])
        utils[func]

      val = f.call ctx, val if f

    val

  utils.splitName = (str) ->
    str = $.trim str
    lname = if str.match /,/
      arr = str.split(/\s*,\s*/)
      arr.shift()
    else
      arr = str.split(/\s+/)
      arr.pop()

    fname = arr.join ' '

    [ $.trim(fname), $.trim(lname) ]

  utils.joinName = (first, last) ->
    names = []
    names.push n for n in [ $.trim(first), $.trim(last) ] when n
    names.join ' '

  utils.parseJSON = (str) ->
    try
      ret = JSON.parse str
    ret

  utils.getProtocol = ->
    window.location?.protocol

  utils.getHost = ->
    window.location?.host

  utils.getOrigin = ->
    utils.getProtocol() + '//' + utils.getHost()

  utils.shareUrlSocial = (url, prov) ->
    base = if prov is 'FB'
      'https://www.facebook.com/sharer/sharer.php?u='
    else
      'https://plus.google.com/share?url='

    base + encodeURIComponent(url)

  utils.mailtoLink = (recip, opts) ->
    lnk = "mailto:#{recip}"
    if _.isEmpty opts
      lnk
    else
      params = []
      for param of opts
        params.push param + '=' + encodeURIComponent(opts[param])
      lnk + '?' + params.join('&')

  utils.isValidDbDate = (str) ->
    utils._chkRegExp str, 'REG_DT_ISO'

  utils.isValidIso8601Date = (str) ->
    utils._chkRegExp str, 'REG_DT_ISO8601'

  utils.parseDbDate = (str) ->
    if utils.isValidDbDate str
      moment.utc(str, utils.FMT_DT_ISO).local()
    else
      str

  utils.dbDateToIso8601 = (str) ->
    m = utils.parseDbDate str
    if _.isObject(m) then m.format(utils.FMT_DT_ISO8601) else str

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
      ret = null unless ret && utils.isValidDate ret

    ret

  utils.formatDate = (dm, opts) ->
    opts ?= {}
    m = if dm? && _.isString dm
      utils.parseDate dm
    else
      dm

    if m
      if opts.time
        utils._formatDateTime m
      else if opts.short
        utils._formatShortDate m
      else
        utils._formatDate m
    else
      ''

  utils.formatDateTime = (dm, opts) ->
    utils.formatDate dm, _.extend {}, opts, time: true

  utils.formatDateTimeSmart = (dm, opts) ->
    # TODO: more intelligence: omitting year, using yesterday, tomorrow etc.
    m = if dm? && _.isString dm
      utils.parseDate dm
    else
      dm

    return '' unless m

    time_format = if m.minutes() is 0
      utils.getConfig('time_only_hour_format') || 'ha'
    else
      utils.getConfig('time_format') || 'h:mma'

    if moment().format('YYYY-MM-DD') is moment(m).format('YYYY-MM-DD')
      m.format time_format
    else
      m.format(if utils.isDateWithinAYear m
        (utils.getConfig('short_date_format') || 'D MMM') + " #{time_format}"
      else
        (utils.getConfig('date_format') || 'D MMM YYYY') + " #{time_format}")

  utils.formatTime = (dm, opts) ->
    m = if dm? && _.isString dm
      utils.parseTime dm
    else
      dm

    if m then utils._formatTime m else ''

  utils._formatDate = (m) ->
    m.format(utils.getConfig('date_format') || 'D MMM YYYY')

  utils._formatTime = (m) ->
    m.format(utils.getConfig('time_format') || 'h:mm a')

  utils._formatShortDate = (m) ->
    m.format(utils.getConfig('short_date_format') || 'D MMM')

  utils._formatDateTime = (m) ->
    # TODO: datetime format
    utils._formatDate(m) + ' ' + utils._formatTime(m)

  utils.formatTextMonth = (dm) ->
    m = moment dm
    m.format(utils.getConfig('monthformat') || 'MMMM YYYY')

  utils.isDateWithinAYear = (m) ->
    input = moment(m)
    input.isAfter(moment().subtract('months', 6)) &&
      input.isBefore(moment().add('months', 6))

  utils.isValidDate = (m) ->
    m? && m.toDate().toString() != 'Invalid Date' && 2000 < m.year() < 2099

  utils.isValidTime = (m) ->
    _.isObject(m) && (d = m.toDate()).toString() != 'Invalid Date' &&
      (0 <= d.getHours() <= 23) &&
      (0 <= d.getMinutes() <= 59) &&
      (0 <= d.getSeconds() <= 59)

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

  utils.getFmtDateTime = (fmt) ->
    moment().format fmt

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

  utils.roundTo = (val, prec) ->
    val = parseFloat val
    if _.isFinite val
      prec = if _.isFinite(prec) then prec else 0
      parseFloat val.toFixed prec

  utils.mean = (arr) ->
    arrLen = arr?.length
    if arrLen > 1
      mean = arr.reduce (a, b) -> a + b
      mean /= arrLen
    else if arrLen > 0
      mean = arr[0]
    mean

  utils.stDev = (arr) ->
    mean = utils.mean arr
    l = arr.length

    sum = 0
    while l--
      sum += Math.pow(arr[l] - mean, 2)
    Math.sqrt(sum / (arr.length || 1))

  utils.reloadPage = (opts) ->
    opts ?= {}
    window.location.href = opts?.href || window.location.href

  utils.randomGuid = (length) ->
    length ?= 32
    possible = 'abcdef0123456789'

    text = ''
    text += possible.charAt(Math.floor(Math.random() * possible.length)) \
      for i in [ 1 .. length ]
    text

  utils.getIframeDocument = (iframe) ->
    return null unless iframe
    if iframe.contentWindow
      iframe.contentWindow.document
    else
      iframe.contentDocument

  utils
