(($) ->
  # ---- Helpers --------------------------------------------------------------

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
    $.trim(str.replace(/\s+/g, ' ')
              .replace(/&lt;/g, '<')
              .replace(/&gt;/g, '>')
              .replace(/&nbsp;/g, ' ')
              .replace(/&amp;/g, '&')
              .replace(/<br\s*\/?>$/, '')
              .replace(/<br\s*\/?>/g, "\n"))


  $.ntMouseWheelEvent = ->
    if $.ntBrowser 'firefox' then 'DOMMouseScroll' else 'mousewheel'


  $.ntResult = (obj, prop) ->
    return unless obj
    val = obj[prop]

    if $.isFunction obj[prop]
      obj[prop].apply obj, Array.prototype.slice.call arguments, 2
    else
      obj[prop]


  $.ntQuoteMeta = (str) ->
    str ?= ''
    str.replace /([\.\\\+\*\?\[\^\]\$\(\)\-\{\}\|])/g, '\\$1'


  $.ntStartMatch = (str, kw) ->
    $.trim(str).match new RegExp '^' + $.ntQuoteMeta($.trim kw), 'i'


  $.ntForceBlur = ->
    $('<input type="text" style="position: fixed; left: -10000px">')
      .appendTo('body').focus().remove()


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


  # TODO: versions
  $.ntPlatform = (type, ver, platform) ->
    platform ?= navigator.platform
    ret = switch type?.toLowerCase()
      when 'linux' then platform.match /^linux/i
      when 'mac' then platform.match /^mac/i
      when 'win' then platform.match /^win/i

    ret


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


  # ---- Stateless plugins ----------------------------------------------------

  $.fn.ntOuterHtml = ->
    $(@).clone().wrap('<div></div>').parent().html()


  $.fn.ntSelectOptions = (opts) ->
    $(@).html $.ntSelectOptions opts


  $.fn.ntChecked = ->
    $(@).prop('checked') || ''


  $.fn.ntInputVal = (val) ->
    prop = if @[0]?.nodeName?.toLowerCase() in [ 'input', 'textarea' ]
      'val'
    else
      'text'

    if val? then $(@)[prop](val) else $(@)[prop]()


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


  $.fn.ntSetCaretToEnd = ->
    el = $(@).get(0)

    if el.nodeName.toLowerCase() in [ 'input', 'textarea' ]
      len = $(@).val().length
      el.setSelectionRange len, len
    else if window.getSelection? && document.createRange?
      range = document.createRange()
      range.selectNodeContents(el)
      range.collapse false
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange range
    else if document.body.createTextRange?
      textRange = document.body.createTextRange()
      textRange.moveToElementText el
      textRange.collapse false
      textRange.select()

    $(@)


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


  $.fn.ntIsVisibleWithinParent = (opts) ->
    $child = $(@)
    $parent = $(@).parent()

    pScrollTop = $parent.scrollTop()
    pScrollBottom = pScrollTop + $parent.outerHeight()
    cTop = $child.position().top + parseInt($child.css('margin-top') || 0) +
      pScrollTop
    cBottom = cTop + $child.height()

    topMatch = pScrollTop <= cTop <= pScrollBottom
    bottomMatch = pScrollTop <= cBottom <= pScrollBottom

    topMatch && (!opts?.strict || bottomMatch)


  $.fn.ntAnimateTo = (opts) ->
    opts ?= {}
    $elem = $(@)

    # TODO: generic item positioning (font-size) and $orig lookalike $clone
    if $elem.get(0) && opts.to?
      $clone = $elem.clone().appendTo('body')

      fontSize = parseInt $elem.css('font-size')
      $clone.css
        'position'  : 'absolute'
        'font-size' : fontSize + 'px'
        'top'       : $elem.offset().top
        'left'      : $elem.offset().left

      $tgt = $(opts.to)
      tgtPos =
        h : $tgt.show().height()
        w : $tgt.width()
        t : $tgt.offset().top
        l : $tgt.offset().left
      $tgt.hide()

      paddingTop = (tgtPos.h - fontSize) / 2
      paddingLeft = (tgtPos.w - fontSize) / 2

      $clone.animate
        top  : tgtPos.t + paddingTop
        left : tgtPos.l + paddingLeft
      , 400, 'swing', ->
        $(@).remove()
        opts.onDone?.call @
    $(@)


  # ---- Class based plugins --------------------------------------------------

  # ---- Plugin register helpers ----------------------------------------------

  $._ntCreatePlugin = (cname, klass, pname) ->
    (opts) ->
      args = Array.prototype.slice.call arguments, 1
      @each ->
        obj = $(@).data pname

        if typeof(opts) is 'string'
          $.error "Cannot call #{opts}, #{pname} is not present" unless obj
          obj[opts].apply obj, args

          if opts is 'destroy'
            for elem in [ '$el', 'el', 'opts', 'pluginName', 'className' ]
              delete obj[elem]
            $(@).data pname, null

        else if !obj
          $(@).data pname, new klass @, cname, opts

  $._ntRegisterPlugins = (pluginobj) ->
    for name, val of pluginobj
      plugin_name = "nt#{name}"
      $.fn[plugin_name] = $._ntCreatePlugin name, val, plugin_name


  # ---- PluginBase -----------------------------------------------------------

  class $._ntPluginBaseClass
    constructor: (@el, @className, opts) ->
      @$el = $(@el)
      @pluginName = "nt#{@className}"
      @opts = $.extend {}, @defaults, opts
      @init()

    init: -> # should be overridden

  plugins = {}


  # ---- Checkbox -------------------------------------------------------------

  class plugins.Checkbox extends $._ntPluginBaseClass
    defaults:
      'contClass'    : 'nt-checkbox'
      'markTemplate' : '<div><i class="fa fa-check"></i></div>'
      'markClass'    : 'nt-checkmark'
      'checkedClass' : 'nt-checked'

    init: ->
      if @$el.parent()[0].nodeName.toLowerCase() isnt 'label'
        @$el.wrap('<div>')
      else
        @labeled = true

      @$el.hide()
      @$cont = @$el.parent().addClass @opts.contClass
      @$chk = $(@opts.markTemplate).addClass(@opts.markClass).prependTo @$cont
      @adjustChecked()

      @$cont.on 'click', @click unless @labeled
      @$el.on 'change', @adjustChecked

    click: =>
      @$el.prop('checked', !@$el.prop('checked')).trigger 'change'

    adjustChecked: =>
      @$cont.toggleClass @opts.checkedClass, @$el.prop('checked')

    destroy: =>
      @$cont.off 'click', @click unless @labeled
      @$el.off 'change', @adjustChecked

      @$cont.find(".#{@opts.markClass}").remove()

      if @labeled
        @$cont.removeClass @opts.contClass
      else
        @$el.unwrap()

      @$el.show()

      delete @[elem] for elem in [ '$cont', '$chk', 'labeled' ]


  # ---- Radio ----------------------------------------------------------------

  class plugins.Radio extends plugins.Checkbox
    defaults:
      'contClass'    : 'nt-radio'
      'markTemplate' : '<div><i class="fa fa-circle"></i></div>'
      'markClass'    : 'nt-checkmark'
      'checkedClass' : 'nt-checked'

    click: =>
      @$el.prop 'checked', true

    adjustChecked: (e) =>
      super
      if e
        $('input:radio[name=' + @$el.attr('name') + ']').not(@$el)
          .closest(".#{@opts.contClass}").removeClass @opts.checkedClass


  # ---- Dropdown -------------------------------------------------------------

  class plugins.Dropdown extends $._ntPluginBaseClass
    defaults:
      'contClass'  : 'nt-dd-cont'
      'boxClass'   : 'nt-dd'
      'optsClass'  : 'nt-dd-opts'
      'selClass'   : 'nt-selected'
      'hoverClass' : 'nt-itemhover'
      'tabindex'   : 0

    init: ->
      @$el.wrap('<div>').hide()
      $cont = @$el.parent().addClass @opts.contClass

      @$box = $('<div>').addClass(@opts.boxClass)
        .attr('tabindex', @opts.tabindex).appendTo $cont
      @$options = $('<div>').addClass(@opts.optsClass).appendTo $cont

      $ul = $('<ul>')
      @$el.find('option').each (i, el) ->
        $el = $(el)
        $('<li>').html($el.text()).attr('data-value', $el.attr 'value')
          .appendTo $ul

      @$options.append $ul

      # event handlers
      @opts.btn?.click @clickBox
      @$box.click(@clickBox).keydown @keydownBox
      @$options.on 'mouseover', 'li', @hoverOption
      @$options.on 'click', 'li', @clickOption
      $(document).on 'click', @clickDoc

      @setValue @$el.val()

    clickDoc: (e) =>
      $tgt = $(e.target)
      if !$tgt.closest('.' + @opts.contClass)[0] &&
          !$tgt.closest(@opts.btn)[0]
        @toggleOptions false

    clickOption: (e) =>
      @setValue $(e.target)
      @$box.focus()

    clickBox: =>
      @toggleOptions()
      @$box.focus()

    keydownBox: (e) =>
      key = e.which
      # key codes: ENTER: 13, ESC: 27, UP: 38, DOWN: 40
      if key in [ 13, 27, 38, 40 ]
        if key == 27
          @toggleOptions false
        else if @$options.is ':visible'
          if key in [ 38, 40 ]
            $hover = @$options.find '.' + @opts.hoverClass
            $sibling = $hover[ if key == 38 then 'prev' else 'next' ]()

            if $sibling[0]
              $hover.removeClass @opts.hoverClass
              $sibling.addClass @opts.hoverClass
          else
            @setValue @$options.find '.' + @opts.hoverClass
        else
          @toggleOptions true

        false

    toggleOptions: (show) =>
      func = if show?
        if show then 'Down' else 'Up'
      else
        'Toggle'

      @$options['slide' + func](100, =>
        @$options.find('li').removeClass(@opts.hoverClass)
          .filter('.' + @opts.selClass).addClass @opts.hoverClass
      )

    hoverOption: (e) =>
      $(e.target).addClass(@opts.hoverClass).siblings()
        .removeClass @opts.hoverClass

    setValue: (val) =>
      return unless val?
      $items = @$options.find('li')

      if typeof(val) is 'object'
        $selitem = $(val)
      else
        $items.each (i, el) ->
          if $(el).data('value') is val.toString()
            $selitem = $(el)
            return

      if $selitem
        $curritem = $items.filter '.' + @opts.selClass

        if $selitem[0] isnt $curritem[0]
          $items.removeClass @opts.selClass
          $selitem.addClass @opts.selClass
          @$box.text $selitem.text()
          val = $selitem.data 'value'
          @$el.val(val).trigger 'change' unless val is @$el.val()

        @toggleOptions false

    destroy: =>
      $(document).off 'click', @clickDoc
      @opts.btn?.off 'click', @clickBox

      @$el.parent().find('.' + @opts.optsClass + ', .' + @opts.boxClass)
        .remove()

      @$el.unwrap().show()

      delete @[elem] for elem in [ '$options', '$box' ]


  # ---- DatePicker -----------------------------------------------------------

  class plugins.DatePicker extends $._ntPluginBaseClass
    defaults:
      closeButton : false
      direction   : 'today-past'

    init: ->
      @opts.parser ?= moment
      @opts.getNow ?= moment
      @$btn = @opts.inputBtn

      # events
      if @$btn
        for ev in [ 'mousedown', 'click' ]
          @$btn.on ev, @[ev + 'Btn']

      for ev in [ 'click', 'focus', 'blur', 'change', 'keydown' ]
        @$el.on ev, @[ev + 'Input']

      @$el.kalendae @opts

    mousedownBtn: (e) =>
      kal = @$el.data('kalendae')?.container
      @$btn.toggleClass 'nt-k-open', kal && $(kal).is ':visible'

    clickBtn: (e) =>
      if @$btn.hasClass 'nt-k-open'
        @$btn.removeClass 'nt-k-open'
      else
        @$el.click()

    focusInput: (e) =>
      @initDate = @opts.parser @$el.val() || @opts.getNow()
      @result = undefined

    blurInput: (e) =>
      if @hasOwnProperty 'result'
        val = @result
        delete @result
        @$el.trigger 'pickdone', val

    clickInput: (e) =>
      @$el.select()

    changeInput: (e) =>
      val = @$el.val().trim().toLowerCase()
      val = 'today' if @opts.todayStr && val is @opts.todayStr.toLowerCase()
      dm = @opts.parser val

      if typeof dm is 'object' && dm.isValid && dm.isValid()
        @result = @$el.val()
      else
        dm = @initDate

      @$el.val moment(dm).format @opts.format
      @$el.blur()

    keydownInput: (e) =>
      act = switch e.keyCode
        when 27 then @$el.val(@initDate.format @opts.format).blur()
        when 13 then @$el.trigger 'change'
      e.preventDefault() if act

    destroy: ->
      if @$btn
        for ev in [ 'mousedown', 'click' ]
          @$btn.off ev, @[ev + 'Btn']

      for ev in [ 'click', 'focus', 'blur', 'change', 'keydown' ]
        @$el.off ev, @[ev + 'Input']

      @$el.data('kalendae')?.destroy()

      for elem in [ '$btn', 'initDate', 'result' ]
        delete @[elem]


  # ---- ContentSpy -----------------------------------------------------------

  class plugins.ContentSpy extends $._ntPluginBaseClass
    defaults:
      delay      : 200
      ignoreCase : true

    init: ->
      if @el.nodeName.toLowerCase() in [ 'input', 'textarea' ]
        @$el.on ev, @[ev + 'Input'] for ev in [ 'focus', 'blur', 'keydown' ]
      else if @$el.attr 'contenteditable'
        @conted = true
        if window.MutationObserver
          @observer = new MutationObserver @subtreeModified
          @observer.observe @el,
            childList     : true
            subtree       : true
            characterData : true
        else
          @$el.on 'DOMSubtreeModified', @subtreeModified

    subtreeModified: =>
      clearTimeout @_subtree_change_timer
      @_subtree_change_timer = setTimeout =>
        @$el.trigger 'contentchange', [ @$el.text() ]
      , @opts.delay

    focusInput: (e) =>
      @initVal = @$el.val()
      @startInspect focus: true

    blurInput: (e) =>
      @stopInspect()

    keydownInput: (e) =>
      @stopInspect()
      @nextInspect()

    startInspect: (opts) =>
      return if opts?.focus && @_inspect_timer
      @stopInspect()
      currVal = @$el.val()

      if @opts.ignoreSelection # works only for text inputs / textareas
        start = @el.selectionStart || 0
        end = @el.selectionEnd || 0
        if start < end
          currVal = currVal.substr(0, start) + currVal.substr(end)

      if currVal.toLowerCase() isnt @initVal.toLowerCase() ||
          !@opts.ignoreCase && currVal isnt @initVal
        prevVal = @initVal
        @initVal = currVal
        @$el.trigger 'contentchange', [ currVal, prevVal ]

      @nextInspect()

    nextInspect: =>
      @_inspect_timer = setTimeout @startInspect, @opts.delay

    stopInspect: =>
      clearTimeout @_inspect_timer
      delete @_inspect_timer

    destroy: =>
      if @conted
        if @observer
          @observer.disconnect()
          delete @observer
        else
          @$el.off 'DOMSubtreeModified', @subtreeModified

        clearTimeout @_subtree_change_timer
        delete @[prop] for prop in [ 'conted', '_subtree_change_timer' ]
      else
        @stopInspect()
        @$el.off ev, @[ev + 'Input'] for ev in [ 'focus', 'blur', 'keydown' ]
        delete @initVal


  # ---- AutoSuggest ----------------------------------------------------------

  class plugins.AutoSuggest extends $._ntPluginBaseClass
    defaults:
      inputClass      : 'nt-as-input'
      listTemplate    : '<ul></ul>'
      listClass       : 'nt-as-list'
      itemTemplate    : '<li><i></i><span></span></li>'
      itemClass       : 'nt-as-item'
      itemHoverClass  : 'nt-as-item-hover'
      itemSelClass    : 'nt-as-item-sel'
      itemSearchClass : 'nt-as-item-search'
      itemLimit       : 10
      iconOnlySearch  : true

    init: ->
      if !$.isFunction(@opts.source) && !$.isArray(@opts.source)
        @opts.source = []

      @$el.ntContentSpy().addClass(@opts.inputClass)
        .on('contentchange', @processText)
        .on('blur', @blurInput)
        .on('keydown', @keydownInput)

    getVal: => @$el.ntInputVal().trim()

    fillInput: (text, opts) =>
      @select = true if opts?.select
      @$el.ntInputVal(text).ntSetCaretToEnd()

    processText: (e) =>
      return unless document.activeElement is @el

      if @select
        delete @select
        return

      val = @getVal()
      if val
        @searchItems(val).done (items) =>
          return unless @$el && @getVal() is val
          items ?= []
          if items.length
            for item, i in items
              if item.toLowerCase() is val.toLowerCase()
                idx = i
                break

            items.splice idx, 1 if idx
            items.unshift val if !idx? || idx

          @buildItems items
      else
        @hideItems()

    searchItems: (txt) =>
      if $.isFunction @opts.source
        @opts.source txt
      else
        $.Deferred().resolve \
          $.grep @opts.source, (n, i) -> $.ntStartMatch n, txt

    buildItems: (items) =>
      if !items?.length
        @hideItems()
        return

      itemSelector = ".#{@opts.itemClass}"

      if @$listEl
        @$listEl.detach()
      else
        @$listEl = $(@opts.listTemplate).addClass(@opts.listClass)
          .on 'mousedown', itemSelector, (e) =>
            @fillInput $(e.target).closest(itemSelector).data 'descr'
            @hideItems()

      @$listEl.css width: @$el.outerWidth() if @opts.autoWidth

      if $.isPlainObject @opts.listClassByParent
        for p, c of @opts.listClassByParent
          @$listEl.addClass c if p && c && @$el.closest(p).get(0)

      $itemCont = if @opts.itemCont
        @$listEl.find(@opts.itemCont)
      else
        @$listEl

      $itemCont.empty()

      for item, i in items
        break if i > @opts.itemLimit - 1
        $item = $(@opts.itemTemplate).addClass(@opts.itemClass).data 'descr', item
        $item.addClass @opts.itemSelClass + ' ' + @opts.itemSearchClass unless i
        if @opts.iconClass && (!@opts.iconOnlySearch || !i)
          $item.find('i').addClass @opts.iconClass
        else
          $item.find('i').hide()
        $item.find('span').html $.ntEncodeHtml item
        $itemCont.append $item

      ih = @$el.outerHeight()
      top = @$el.offset().top + ih + 1
      left = @$el.offset().left
      @$listEl.appendTo('body').show().css top: top, left: left

      # browser window outreach correction
      ww = $(window).width()
      lw = @$listEl.outerWidth()
      @$listEl.css left: ww - lw if ww < left + lw

      lh = @$listEl.outerHeight()
      if top + lh > $(window).height() && (uptop = top - lh - ih - 2) > 0
        @$listEl.find(".#{@opts.itemSearchClass}").appendTo @$listEl
        @$listEl.css top: uptop

    hideItems: =>
      @$listEl?.hide()

    destroyItems: =>
      @$listEl?.remove()
      delete @$listEl

    keydownInput: (e) =>
      return unless @$listEl?.is(':visible') && e.which in [ 13, 27, 38, 40 ]

      # key codes: ENTER: 13, ESC: 27, UP: 38, DOWN: 40
      if e.which == 13
        @hideItems()
      else
        e.preventDefault()

        $sel = @$listEl.find ".#{@opts.itemSelClass}"

        $sib = if e.which == 27
          @$listEl.find ".#{@opts.itemSearchClass}"
        else if e.which == 38
          if $sel
            $sel.prev()
          else
            @$listEl.find ".#{@opts.itemClass}:first"
        else if $sel
          $sel.next()
        else
          @$listEl.find @opts.itemClass + ':last'

        if e.which == 27 && $sib[0] && $sel[0] && $sib[0] is $sel[0]
          @hideItems()
        else if $sib[0]
          $sel.removeClass @opts.itemSelClass
          $sib.addClass @opts.itemSelClass
          @fillInput $sib.data('descr'), select: true

    blurInput: (e) =>
      @destroyItems()

    destroy: =>
      @destroyItems()

      @$el.ntContentSpy('destroy').off 'contentchange', @processText
      @$el.off ev, @[ev + 'Input'] for ev in [ 'keydown', 'blur' ]

      delete @select


  # ---- Modal ----------------------------------------------------------------

  class plugins.Modal extends $._ntPluginBaseClass
    defaults:
      'modalClass'     : 'nt-modal'
      'modalShowClass' : 'nt-modal-show'
      'bgClass'        : 'nt-modal-bg'
      'bgFadeTime'     : 200
      'transitionTime' : 200

    init: ->
      @$el.addClass(@opts.modalClass).appendTo 'body'
      @show() if @opts.show

    triggerBgClick: =>
      @$el.trigger 'bgclickmodal'

    show: =>
      return if @$el.hasClass @opts.modalShowClass

      @$bg = $('<div>').addClass(@opts.bgClass).appendTo('body')
        .fadeIn @opts.bgFadeTime, =>
          @$el.addClass @opts.modalShowClass
          @_showTimer = setTimeout =>
            @$el.trigger 'showmodal'
            @$bg.on 'click', @triggerBgClick
          , @opts.transitionTime

    hide: (opts) =>
      clearTimeout @_showTimer
      return unless @$el.hasClass @opts.modalShowClass

      @$el.removeClass @opts.modalShowClass

      _removeBg = =>
        @$bg?.off 'click', @triggerBgClick
        @$bg?.remove()
        delete @$bg
        @$el.trigger 'hidemodal'

      if opts?.destroy || !@$bg
        _removeBg()
      else
        @$bg.fadeOut @opts.bgFadeTime, _removeBg

    destroy: =>
      @hide destroy: true
      delete @_showTimer
      @$el.removeClass(@opts.modalClass).detach()


  # ---- Tabs -----------------------------------------------------------------

  class plugins.Tabs extends $._ntPluginBaseClass
    defaults:
      'contSelector'       : '.nt-tabs'
      'tabSelector'        : '.nt-tab'
      'activeClass'        : 'nt-active'
      'leftArrowSelector'  : '.nt-btn-left'
      'rightArrowSelector' : '.nt-btn-right'
      'scrollDelay'        : 200

    init: ->
      @$cont = @$el.find @opts.contSelector
      @$tabs = @$cont.find @opts.tabSelector
      @$leftArrow = @$el.find @opts.leftArrowSelector
      @$rightArrow = @$el.find @opts.rightArrowSelector

      @adjustArrows()

      @$tabs.click @clickTab
      @$leftArrow.click @scrollLeft
      @$rightArrow.click @scrollRight

    adjustArrows: =>
      scrollLeft = @$cont.scrollLeft()
      @$leftArrow.toggle scrollLeft > 0
      @$rightArrow.toggle \
        @$tabs.last()[0]?.offsetLeft >= scrollLeft + @$cont.width()

    scroll: (dst) =>
      scrollPos = null

      if dst in [ 'left', 'right' ]
        @$tabs.each (i, el) =>
          offset = @scrollOffset el, dst
          if offset?
            scrollPos = offset
            false if dst is 'right'
      else if $(dst)[0]
        scrollPos = @scrollOffset dst

      if scrollPos?
        if @opts.scrollDelay
          @$cont.animate scrollLeft: scrollPos, @opts.scrollDelay, @adjustArrows
        else
          @$cont.scrollLeft scrollPos
          @adjustArrows()

    scrollOffset: (tab, dir) =>
      $tab = $(tab)
      if $tab[0]
        if (!dir || dir is 'left') && $tab.position().left < 0
          $tab[0].offsetLeft
        else if !dir || dir is 'right'
          rightEdge = $tab[0].offsetLeft + $tab.outerWidth()
          contWidth = @$cont.width()
          rightEdge - contWidth if rightEdge > @$cont.scrollLeft() + contWidth

    scrollLeft: => @scroll 'left'

    scrollRight: => @scroll 'right'

    clickTab: (e) =>
      @activate $(e.target).closest @opts.tabSelector

    activate: (tab) =>
      $tab = if typeof tab is 'object'
        $(tab)
      else if typeof tab is 'number'
        @$tabs.eq parseInt tab
      else
        @$tabs.filter tab

      if $tab
        @$tabs.not($tab).removeClass @opts.activeClass
        if !$tab.hasClass @opts.activeClass
          $tab.addClass(@opts.activeClass).trigger 'activate'
        @scroll $tab

    destroy: =>
      @$tabs.off 'click', @clickTab
      @$leftArrow.off 'click', @scrollLeft
      @$rightArrow.off 'click', @scrollRight

      delete @[prop] for prop in [ '$cont', '$tabs', '$leftArrow',
                                   '$rightArrow' ]


  # ---- AutoScroll -----------------------------------------------------------

  class plugins.AutoScroll extends $._ntPluginBaseClass
    defaults:
      border    : '20%'
      borderMax : 100
      speed     : 500 # px / sec

    init: ->
      for action in [ 'start', 'stop' ]
        @$el.on "#{action}autoscroll", @[action]

    start: (e) =>
      @stop()
      $('body').on 'mousemove', @mouseMove

    stop: =>
      $('body').off 'mousemove', @mouseMove

    mouseMove: (e) =>
      offset = @$el.offset()
      w = @$el.outerWidth()
      h = @$el.outerHeight()
      x = e.pageX - offset.left
      y = e.pageY - offset.top

      border = if @opts.border.match /\%$/
        h * parseInt(@opts.border) / 100
      else
        @opts.border
      border = @opts.borderMax if @opts.borderMax? && border > @opts.borderMax

      if 0 <= x <= w
        scrollTop = if 0 <= y <= border
          0
        else if h - border <= y <= h
          @el.scrollHeight

      @$el.stop()
      if scrollTop?
        @$el.animate scrollTop: scrollTop,
          parseInt(Math.abs(@$el.scrollTop() - scrollTop) / @opts.speed * 1000)

    destroy: =>
      for action in [ 'start', 'stop' ]
        @$el.off "#{action}autoscroll", @[action]
      @stop()


  # ---- Register class based plugins -----------------------------------------

  $._ntRegisterPlugins plugins

)(jQuery)
