(($) ->
  # CONFIG
  defaults =
    ntAutoSuggest:
      'inputClass'         : 'nt-as-input'
      'listTemplate'       : '<ul></ul>'
      'listClass'          : 'nt-as-list'
      'itemTemplate'       : '<li><i></i><span></span></li>'
      'itemClass'          : 'nt-as-item'
      'itemSelClass'       : 'nt-as-item-sel'
      'itemLimit'          : 10
      'autoComplete'       : true
      'selectOnlyFromList' : false

    ntInputAlert:
      'alertSelector' : '.alert'
      'alertClass'    : 'nt-error'

    ntContentSpy:
      'delay'      : 200
      'ignoreCase' : true


  # HELPERS
  $.ntEncodeHtml = (str) ->
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


  $.ntDecodeHtml = (str) ->
    return str unless str?
    str = str.toString()
    $.trim str.replace(/\s+/g, ' ')
              .replace(/&lt;/g, '<')
              .replace(/&gt;/g, '>')
              .replace(/&nbsp;/g, ' ')
              .replace(/&amp;/g, '&')
              .replace(/<br\s*\/?>$/, '')
              .replace(/<br\s*\/?>/g, "\n")


  $.fn.ntOuterHtml = ->
    $(@).clone().wrap('<div></div>').parent().html()


  $.ntQuoteMeta = (str) ->
    str ?= ''
    str.replace /([\.\\\+\*\?\[\^\]\$\(\)\-\{\}\|])/g, '\\$1'


  $.ntStartMatch = (str, kw) ->
    $.trim(str).match new RegExp '^' + $.ntQuoteMeta($.trim kw), 'i'


  $.ntSelectOptions = (opts) ->
    ret = ''
    for opt in (opts?.options || [])
      if typeof opt is 'object' && opt.value?
        value = $.ntEncodeHtml opt.value
        descr = if opt.descr? then $.ntEncodeHtml opt.descr else value
        ret += "<option value=\"#{value}\""
        ret += ' selected="selected"' if opt.sel
        ret += ">#{descr}</option>"

    ret


  $.fn.ntSelectOptions = (opts) ->
    $(@).html $.ntSelectOptions opts


  $.fn.ntChecked = ->
    $(@).prop('checked') || ''


  $.fn.ntInputVal = ->
    if @[0]?.nodeName?.toLowerCase() in [ 'input', 'textarea' ]
      $(@).val()
    else
      $(@).html()


  $.fn.ntCleanHtml = ->
    txt = $(@).text()
    if $.trim txt
      $(@).html()
    else
      ''


  $.fn.ntWrapInTag = (opts) ->
    opts ?= {}
    opts.type ?= 'div'
    opts.attrs ?= {}

    @each ->
      $tag = $(@).wrap("<#{opts.type}>").parent()
      for key of opts.attrs
        val = opts.attrs[key]
        attr = if key is 'mailto'
          val = "mailto:#{val}"
          'href'
        else
          key
        $tag.attr attr, val


  $.fn.ntWrapInA = (opts) ->
    $(@).ntWrapInTag $.extend {}, opts, type: 'a'


  # FUNCTIONAL PLUGINS

  # Usage: $.ntBrowser('firefox'), $.ntBrowser('ie','10-')
  $.ntBrowser = (type, ver, ua) ->
    ua = navigator.userAgent unless ua
    switch type?.toLowerCase()
      when 'ie' then ret = ua.match(/trident.+rv:(\d+)/i) || ua.match(/msie\s+(\d+)/i)
      when 'firefox' then ret = ua.match /firefox\/(\d+)/i
      when 'chrome' then ret = ua.match /chrome\/(\d+)/i
      when 'safari' then ret = ua.match /version\/(\d+).+safari/i

    if ret
      ret = parseInt ret[1]
      verChk = ver?.toString().match(/^(\d+)([+-]?)$/)
      if verChk
        num = parseInt verChk[1]
        rel = verChk[2]

        ret = if rel
          if rel is '+' then ret >= num else ret <= num
        else
          ret == num

    ret

  $.fn.ntContentSpy = (opts) ->
    opts = $.extend {}, defaults.ntContentSpy, opts

    startInspect = (status, iopts) ->
      return if iopts?.focus && status.to
      stopInspect.call @, status
      currVal = $(@).ntInputVal()

      if opts.ignoreSelection
        start = @selectionStart || 0
        end = @selectionEnd || 0
        if start < end
          currVal = currVal.substr(0, start) + currVal.substr(end)

      if (currVal.toLowerCase() isnt status.val.toLowerCase()) ||
          (!opts.ignoreCase && currVal isnt status.val)
        prevVal = status.val
        status.val = currVal
        $(@).trigger 'contentchange', [ currVal, prevVal ]

      nextInspect.call @, status

    nextInspect = (status) ->
      status.to = setTimeout =>
        startInspect.call @, status
      , opts.delay

    stopInspect = (status) ->
      clearTimeout status.to
      status.to = null

    @each ->
      status = val: $(@).ntInputVal()

      $(@).focus (e) ->
        startInspect.call @, status, focus: true

      $(@).blur (e) ->
        stopInspect.call @, status

      $(@).keydown (e) ->
        stopInspect.call @, status
        nextInspect.call @, status


  $.fn.ntInputAlert = (opts) ->
    opts = $.extend {}, defaults.ntInputAlert, opts

    getAlertEl = opts.getAlertEl || ->
      # TODO: more advanced selector if needed
      $(@).siblings(opts.alertSelector)

    hideAlert = (e) ->
      $(@).removeClass opts.alertClass
      if opts.multiple
        $(@).siblings('input').removeClass opts.alertClass
      getAlertEl.call(@).slideUp 'fast'

    showAlert = (e, msg, showOpts) ->
      $a = getAlertEl.call @
      msg = $.ntEncodeHtml msg unless showOpts?.skipEncode
      $a.html msg
      $a.slideDown 'fast' unless $a.is ':visible'
      $(@).addClass(opts.alertClass).focus().select()
      if showOpts?.multiple
        $(@).siblings('input').addClass opts.alertClass

    @each ->
      if !$(@).data 'ntInputAlert'
        $(@).ntContentSpy delay: 100 unless $(@).data 'ntContentSpy'
        $(@).data('ntInputAlert', {})
          .on('contentchange hidealert', $.proxy hideAlert, @)
          .on('showalert', $.proxy showAlert, @)


  $.fn.ntSelectElementContents = (opts) ->
    select = (elem) ->
      if $(elem).get(0).nodeName.toLowerCase() in [ 'input', 'textarea' ]
        $(elem).select()
      else if window.getSelection && document.createRange
        range = document.createRange()
        range.selectNodeContents $(elem).get(0)
        sel = window.getSelection()
        sel.removeAllRanges()
        sel.addRange range
      else if document.body.createTextRange
        range = document.body.createTextRange()
        range.moveToElementText $(elem).get(0)
        range.select()

    delay = if opts?.delay then parseInt opts?.delay else 1
    if delay
      setTimeout =>
        select @
      , delay
    else
      select @


  # NOTE: document blur (outside click) is handled in app for lighter global event load
  $.fn.ntAutoSuggest = (opts) ->
    opts = $.extend {}, defaults.ntAutoSuggest, opts
    opts.source = [] unless $.isFunction(opts.source) || $.isArray(opts.source)

    processText = (e, currVal, prevVal) ->
      currVal = currVal?.trim()
      prevVal = prevVal?.trim()
      if currVal
        searchItems.call(@, currVal).done (items) =>
          return unless $(@).val().trim() is currVal
          $(@).data('ntAutoSuggest').items = items || []
          buildItems.call @, items
          if items?.length && opts.autoComplete &&
              currVal?.length > prevVal?.length
            autoCompleteText.call @, items[0]
      else
        hideItems.call @

    hasSelection = -> (@selectionEnd || 0) > (@selectionStart || 0)

    autoCompleteText = (item) ->
      currVal = $(@).val().trim()
      currVal = currVal.substr(0, @selectionStart) if hasSelection.call @
      if currVal.length && item?.length
        $(@).val item
        if currVal.length < item.length
          @selectionStart = currVal.length
          @selectionEnd = item.length

    searchItems = (txt) ->
      if typeof opts.source is 'function'
        opts.source txt
      else
        $.Deferred().resolve $.grep opts.source, (n, i) -> $.ntStartMatch n, txt

    buildItems = (items) ->
      if !items?.length
        hideItems.call @
        return

      itemSelector = ".#{opts.itemClass}"
      data = $(@).data('ntAutoSuggest')

      $list = if data.listEl
        data.listEl.detach()
      else
        data.listEl = $(opts.listTemplate).addClass(opts.listClass)
          .on('mouseenter', itemSelector, (e) ->
            $list.find(itemSelector).removeClass opts.itemSelClass
            $(@).addClass opts.itemSelClass)
          .on('mousedown', itemSelector, (e) ->
            data.itemSelected = $(@).data 'descr')

      if $.isPlainObject opts.listClassByParent
        for p, c of opts.listClassByParent
          $list.addClass c if p && c && $(@).closest(p).get(0)

      $itemCont = if opts.itemCont then $list.find(opts.itemCont) else $list
      $itemCont.empty()

      for item, i in items
        break if i > opts.itemLimit - 1
        $item = $(opts.itemTemplate).addClass(opts.itemClass).data 'descr', item
        $item.addClass opts.itemSelClass unless i
        $item.find('i').addClass opts.iconClass if opts.iconClass
        $item.find('span').html $.ntEncodeHtml item
        $itemCont.append $item

      top = $(@).offset().top + $(@).outerHeight()
      left = $(@).offset().left
      $list.appendTo('body').show().css top: "#{top}px", left: "#{left}px"
      ww = $(window).width()
      lw = $list.outerWidth()
      $list.css left: (ww - lw) + 'px' if ww < left + lw

    hideItems = ->
      $(@).data('ntAutoSuggest').listEl?.hide()

    destroyItems = ->
      data = $(@).data('ntAutoSuggest')
      data.listEl?.remove()
      delete data.listEl

    handleKeydown = (e) ->
      val = $(@).val().trim()
      data = $(@).data 'ntAutoSuggest'
      $list = data.listEl
      $sel = $list.find ".#{opts.itemSelClass}" if $list?.is(':visible')
      e.preventDefault() if e.keyCode in [ 13, 27 ]

      # key codes: BACKSPACE: 8, ENTER: 13, ESC: 27, UP: 38, DOWN: 40, DEL: 46
      if e.keyCode == 13
        item = if opts.selectOnlyFromList
          if $sel?[0]
            $sel.data('descr')
          else if data.items
            $.grep(data.items, (n) -> n.toLowerCase() is val.toLowerCase())[0]
        else if val
          val
        $(@).trigger 'itemselected', item if item
      else if $sel?[0] && e.keyCode in [ 8, 27, 38, 40, 46 ]
        if e.keyCode == 27 || (e.keyCode in [ 8, 46 ] && hasSelection.call(@))
          $(@).val val.substr 0, @selectionStart if @selectionStart
          hideItems.call @
        else if e.keyCode in [ 38, 40 ]
          e.preventDefault()
          $sib = $sel[ if e.keyCode == 38 then 'prev' else 'next' ]()
          if $sib[0]
            $sel.removeClass opts.itemSelClass
            $sib.addClass opts.itemSelClass
            autoCompleteText.call @, $sib.data 'descr' if opts.autoComplete

    handleBlur = (e) ->
      destroyItems.call @
      data = $(@).data 'ntAutoSuggest'
      if data.itemSelected
        $(@).trigger 'itemselected', data.itemSelected
        setTimeout =>
          $(@).focus()
        , 100
        delete data.itemSelected
      else
        val = $(@).val().trim()
        if opts.addOnBlur && val
          $(@).trigger 'itemselected', val
        else
          $(@).val ''

    @each ->
      if !$(@).data 'ntContentSpy'
        $(@).ntContentSpy ignoreSelection: opts.autoComplete

      if !$(@).data 'ntAutoSuggest'
        $(@).addClass(opts.inputClass).data('ntAutoSuggest', {})
          .on('contentchange', $.proxy processText, @)
          .on('blur', $.proxy handleBlur, @)
          .on('keydown', $.proxy handleKeydown, @)
          .on('itemselected', -> $(@).val '')

)(jQuery)
