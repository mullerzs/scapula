define (require) ->
  utils = require 'utils'

  mvconv = {}

  mvconv.html = (dir, val) ->
    if dir is 'ViewToModel'
      utils.decodeHtml utils.stripPh(val)
    # else
    #   utils.encodeHtml val

  mvconv.time = (dir, val, attr, model) ->
    if dir is 'ViewToModel'
      t = utils.parseTime val
      if t
        dt = model.get attr
        val = utils.updateIsoDateTime dt, time: t
    else
      val = utils.formatTime val

    val

  mvconv.date = (dir, val, attr, model) ->
    if dir is 'ViewToModel'
      d = utils.parseDate val
      if d
        dt = model.get attr
        val = utils.updateIsoDateTime dt, date: d
    else
      val = utils.formatDate val

    val

  mvconv.pct = (dir, val) ->
    if dir is 'ModelToView'
      utils.formatPct val

  mvconv.float = (dir, val) ->
    if dir is 'ViewToModel'
      val = parseFloat val
      val = undefined if isNaN val

    val

  mvconv.flag = (dir, val) ->
    if dir is 'ViewToModel'
      val = if val then '1' else ''
    val

  mvconv.invFlag = (dir, val) ->
    if val then '' else '1'

  mvconv.trimText = (dir, val) ->
    if dir is 'ViewToModel'
      val = $.trim val
    val

  mvconv.seqNum = (dir, val) ->
    if dir is 'ModelToView'
      val = val + '.' if val?
    val

  mvconv
