define (require) ->
  mvconv = {}

  mvconv.float = (dir, val) ->
    if dir is 'ViewToModel'
      val = parseFloat val
      val = null if isNaN val

    val

  mvconv.float0 = (dir, val) ->
    if dir is 'ViewToModel'
      val = parseFloat val
      val = 0 if isNaN val

    val

  mvconv.flag = (dir, val) ->
    if dir is 'ViewToModel'
      val = if val then '1' else ''
    val

  mvconv.trimText = (dir, val) ->
    if dir is 'ViewToModel'
      val = $.trim val
    else
      val = '' unless val?

    val

  mvconv.seqNum = (dir, val) ->
    if dir is 'ModelToView'
      val = val + '.' if val?
    val

  mvconv.seqNumHash = (dir, val) ->
    if dir is 'ModelToView'
      val = '#' + val if val?
    val

  mvconv
