(($) ->
  defaults =
    ntSortable:
      'placeholder'          : 'nt-qsort-ph'
      'forcePlaceholderSize' : true
      'opacity'              : '0.8'
      'axis'                 : 'y'
      # TODO: is delay needed? Sortable is untestable if set...
      # 'delay'                : 200
      'cancel'               : 'select,textarea,input'
      'tolerance'            : 'pointer'


    ntDraggable:
      'helper'   : 'clone'
      'revert'   : 'invalid'
      'distance' : 10
      'opacity'  : 0.6
      'cursor'   : 'move'
      'zIndex'   : 1000
      'appendTo' : 'body'
      'cursorAt' : { 'left': -1, 'top': -1 }


    ntAccordion:
      'header'      : '.nt-acc-header'
      'heightStyle' : 'content'
      'activate'    : (e, ui) =>
        ui.newPanel.find('.nt-search-input').focus()


    ntAccordionDropTarget:
      'header'     : '.nt-acc-header'
      'content'    : '.nt-acc-content'
      'target'     : '.nt-acc-content'


    ntFlexAccordion:
      'minHeight'    : 50
      'animateSpeed' : 'fast'
      'clickEvent'   : 'click.ntFlexAccordion'
      'activeClass'  : 'nt-flex-acc'
      'openClass'    : 'nt-acc-open'
      'bodyClass'    : 'accordion-body'
      'headClass'    : 'accordion-heading'
      'grpClass'     : 'nt-acc-group'
      'innerClass'   : 'accordion-inner'
      'tgClass'      : 'accordion-toggle'


    ntScrollToMe:
      'speed' : 'fast'


    ntAutoScroll:
      'speed'     : 'normal'
      'borderPct' : 30


    ntColorPicker:
      'border'     : '1px solid black'
      'columns'    : 8
      'cellWidth'  : 20
      'cellHeight' : 20
      'cellMargin' : 1
      'colors'     : [
        '3366CC', 'C0C0C0', '808080', '000000', 'FF0000', '800000',
        'FFFF00', '808000', '663300', '008000', '00FFFF', '008080',
        '0000FF', '000080', 'FF99CC', '800080'
      ]


    ntTimePicker:
      'amString'   : 'am'
      'pmString'   : 'pm'
      'valAttr'    : 'tp-val'
      'typeAttr'   : 'tp-type'
      'selAttr'    : 'tp-selected'
      'selBg'      : '#7EA0E2',
      'selColor'   : 'white',
      'unSelBg'    : 'white',
      'unSelColor' : 'black',
      'times'      : [
        '00', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'
      ],
      'types' :
        'h'    : 'timepicker-hour',
        'm'    : 'timepicker-min',
        'ampm' : 'timepicker-ampm'
      ,
      'columns'    : 2,
      'rows'       : 12,
      'padding'    : 5,
      'cellWidth'  : 15,
      'cellHeight' : 15,
      'cellMargin' : 1,
      'cellPaddingTop'    : 2,
      'cellPaddingRight'  : 3,
      'cellPaddingBottom' : 2,
      'cellPaddingLeft'   : 2,
      'parseUITime': ->
        $.error 'ntTimePicker: function parseUITime() not specified.'
      'formatUITime': ->
        $.error 'ntTimePicker: function formatUITime() not specified.'
      'isValidTime': ->
        $.error 'ntTimePicker: function isValidTime() not specified.'


    ntDatePicker:
      'parseUIDate': ->
        $.error 'ntTimePicker: function parseUIDate() not specified.'
      'formatUIDate': ->
        $.error 'ntTimePicker: function formatUIDate() not specified.'
      'isValidDate': ->
        $.error 'ntTimePicker: function isValidDate() not specified.'


    ntSharedDateTimePicker:
      'phClass'     : 'nt-copied',
      'origValAttr' : 'nt-orig-val',


    ntTooltip:
      'template' : '<div class="popover nt-tooltip small">
                      <div class="arrow"></div>
                      <div class="popover-inner">
                        <div class="popover-content"><p></p></div>
                      </div>
                    </div>'
      'trigger'  : 'hover'


    ntContEdPh:
      'contClass'      : 'nt-conted-ph-cont'
      'phClass'        : 'nt-ph'
      'contClassStyle' :
        'position' : 'relative'
        'overflow' : 'hidden'
      'phClassStyle'   :
        'position' : 'absolute'
        'top'      : '0px'


  $.fn.ntPicker = (opts) ->
    hideAlert: ->
      opts.hideAlertCB() if opts.hideAlertCB? && $.isFunction opts.hideAlertCB

    showAlert: ->
      opts.showAlertCB() if opts.showAlertCB? && $.isFunction opts.showAlertCB

    cleanupPlaceHolder: (el) ->
      phClass = defaults.ntSharedDateTimePicker.phClass
      $el = $(el)
      if $el.hasClass phClass
        $el.removeClass(phClass).removeAttr 'style'
        $('#' + $el.attr('id') + 'Copy').remove()
        $el.css 'position', 'relative'

    setValWithOrig: (el, val) ->
      origValAttr = defaults.ntSharedDateTimePicker.origValAttr
      $el = $(el)
      origVal = $el.attr origValAttr
      if origVal? && val != origVal
        @onChangeCB val
      $el.attr origValAttr, val
      $el.html val

    restoreValFromOrig: (el) ->
      $el = $(el)
      $el.html $el.attr(defaults.ntSharedDateTimePicker.origValAttr)

    changeContent: (e) ->
      $el = $(e.target)

      tmp = $('<p style="float: left;">' + $el.html() + '</p>')
      $('body').append tmp
      textWidth = tmp.width()
      tmp.remove()

      copiedClass = defaults.ntSharedDateTimePicker.phClass
      if !$el.hasClass copiedClass
        $ph = $('<div id="' + $el.attr('id') + 'Copy">&nbsp</div>')
        $ph.css
          'width'  : $el.width()
          'height' : $el.height()
          'margin' : $el.css 'margin'
          'padding' : $el.css 'padding'
        $el.before $ph

        $el.addClass copiedClass
        $el.css
          'position'  : 'absolute'
          'top'       : $ph.position().top
          'left'      : $ph.position().left
          'z-index'   : 1000
          'min-width' : $el.width()

      if textWidth > opts.currWidth
        if $el.position().left + textWidth <
           $el.parent().offset().left + $el.parent().width()
          $el.width textWidth
      else
        $el.width ''

      # Not checking for function since this is internal
      opts.afterChangeContent e, $el if opts.afterChangeContent?

    onChangeCB: (v) ->
      if opts.onChange? && $.isFunction opts.onChange
        opts.onChange v


  ntIdCounter = 0
  ntUniqueId = (prefix) ->
    id = ntIdCounter++
    if prefix then "#{prefix}.#{id}" else id


  ntPluginId = (plugin) ->
    ntUniqueId "nt.#{plugin}"


  $.fn.ntAttachEvent = (pluginId,event,callback) ->
    $(@).on "#{event}.#{pluginId}", callback


  $.fn.ntDetachEvent = (pluginId,event) ->
    $(@).off "#{event}.#{pluginId}"


  $.fn.ntSortable = (opts) ->
    opts = $.extend {}, defaults.ntSortable, opts
    if !opts.start
      icon = if opts.axis == 'x' then 'icon-arrow-down' else 'icon-arrow-right'
      opts.start = (e,ui) ->
        ui.placeholder.append '<i class="' + icon + '"></i>'

    $(@).sortable opts


  $.fn.ntDraggable = (opts) ->
    opts = $.extend {}, defaults.ntDraggable, opts
    $(@).draggable opts


  $.fn.ntAccordion = (opts) ->
    opts = $.extend {}, defaults.ntAccordion, opts

    $(@).find('.nt-acc-header').append '<i class="nt-icon arrow-up"></i>' +
      '<i class="nt-icon arrow-down"></i>'

    $(@).accordion opts
    if opts.dropTarget
      $(@).accordionDropTarget opts


  $.fn.accordionDropTarget = (opts) ->
    opts = $.extend {}, defaults.ntAccordionDropTarget, opts

    isOver = 0
    if opts?.destroy
      $(opts.header,$(@)).each (i) ->
        $header = $(@).ntDndhover()
        $content = $header.next(opts.content)
        for event in [ 'dragover', 'drop' ]
          $header.removeEventListener event
          $content.removeEventListener event

        for event in [ 'hoverend', 'hoverstart' ]
          $header.off event
          $content.off event

    else
      dtClass = 'nt-droptarget'
      $(opts.header,$(@)).each (i) ->
        $header = $(@).ntDndhover()
        $content = $header.next(opts.content).ntDndhover()
        $target = $header.next(opts.target)

        for $elem in [ $header, $content ]
          $elem.get(0).addEventListener 'dragover', (e) ->
            e.preventDefault() if e.preventDefault
            e.dataTransfer.dropEffect = 'copy'
            false

          $elem.get(0).addEventListener 'drop', (e) ->
            e.preventDefault() if e.preventDefault
            text = e?.dataTransfer?.getData('Text')
            $header.removeClass dtClass
            $content.removeClass dtClass
            $target.trigger 'textdropped', text
            false

          $elem.on 'hoverend', (e) ->
            e.stopPropagation() if e.stopPropagation
            if isOver < 2
              $header.removeClass dtClass
              $content.removeClass dtClass
            isOver--
            false

          $elem.on 'hoverstart', (e) ->
            e.stopPropagation() if e.stopPropagation

            $header.addClass dtClass
            $content.addClass dtClass
            isOver++
            false
    $(@)


  $.fn.ntFlexAccordion = (opts) ->
    opts = $.extend {}, defaults.ntFlexAccordion, opts

    clickEvent = opts.clickEvent
    activeClass = opts.activeClass
    openClass = opts.openClass
    bodyClass = opts.bodyClass
    headClass = opts.headClass
    grpClass = opts.grpClass
    innerClass = opts.innerClass
    tgClass = opts.tgClass

    $base = $(@)

    adjust = (animateSpeed) ->
      $grp = $base.find '.' + grpClass
      subHeight = $grp.outerHeight(true) - $grp.find('.' + bodyClass).outerHeight()
      $colls = $base.find '.' + bodyClass
      $openColls = $base.find '.' + openClass + ' .' + bodyClass

      avHeight = $base.height()
      nonContHeight = subHeight * $colls.length

      nonContHeight += opts.correction if opts?.correction
      destHeight = Math.round(((avHeight - nonContHeight) / $openColls.length) - 1)
      destHeight = opts.minHeight if destHeight < opts.minHeight

      $colls.each ->
        h = if $(@).closest('.' + grpClass).hasClass(openClass) then destHeight + 'px' else 0
        if animateSpeed
          $(@).animate height: h, animateSpeed
        else
          $(@).css height: h

    if opts.destroy
      $base.off(clickEvent).removeClass activeClass
    else
      init = !$base.hasClass activeClass
      if init
        $base.find('.' + innerClass).css
          'overflow-y'         : 'auto'
          'height'             : '100%'
        $base.addClass(activeClass).on clickEvent, '.' + tgClass, ->
          $(@).closest('.' + grpClass).toggleClass(openClass)
            .find('.' + headClass + ' i').toggleClass('arrow-up').toggleClass('arrow-down')
          adjust opts.animateSpeed
      adjust() if init || opts.refresh

    $(@)

  $.fn.ntScrollToMe = (opts) ->
    opts = $.extend {}, defaults.ntScrollToMe, opts

    $par = $(@).parent()
    pstop = $par.scrollTop()
    ph = $par.height()
    otop = $(@).get(0).offsetTop
    h = $(@).height()

    if otop - pstop + h > ph
      $par.animate { scrollTop: otop + h - ph }, opts.speed

    $(@)


  $.fn.ntAutoScroll = (opts) ->
    if opts is 'destroy'
      $(@).stop()
      $(@).off 'mousemove.ntAutoScroll'
      $(@).off 'mouseout.ntAutoScroll'
    else
      opts = $.extend {}, defaults.ntAutoScroll, opts

      $(@).on('mouseout.ntAutoScroll', (e) ->
        $(@).stop()
      ).on 'mousemove.ntAutoScroll', (e) ->
        h = $(@).get(0).scrollHeight
        conth = $(@).height()

        offset = $(@).offset()
        position = (e.pageY - offset.top) / conth

        borderPct = opts.borderPct
        borderPct = 30 unless borderPct && 0 < borderPct <= 50
        borderPct /= 100

        speed = if opts.speed is 'fast' then 500 else 800

        if position < borderPct
          speed = parseInt $(@).scrollTop() / conth * speed
          $(@).stop().animate scrollTop: 0 , speed
        else if position > 1 - borderPct
          speed = parseInt (h - $(@).scrollTop()) / conth * speed
          $(@).stop().animate scrollTop: h , speed
        else
          $(@).stop()


  $.fn.ntChecked = ->
    $(@).prop('checked') || ''


  $.fn.ntContentSpy = ->
    startInspect = (status) ->
      stopInspect.call @, status
      currVal = $(@).val()
      if currVal isnt status.val
        status.val = currVal
        $(@).trigger 'contentchange', currVal

      nextInspect.call @, status

    nextInspect = (status) ->
      status.to = setTimeout =>
        startInspect.call @, status
      , 200

    stopInspect = (status) ->
      clearTimeout status.to

    @each ->
      status = val: $(@).val()

      $(@).focus (e) ->
        startInspect.call @, status

      $(@).blur (e) ->
        stopInspect.call @, status

      $(@).keydown (e) ->
        stopInspect.call @, status
        nextInspect.call @, status


  $.fn.ntOuterHtml = ->
    $(@).clone().wrap('<div></div>').parent().html()


  $.fn.ntBottom = ->
    $(@).offset().top + $(@).outerHeight()


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


  $.fn.ntSetBorderRadius = (val) ->
    prop = 'border-radius'
    tmp = {}
    for i in [ '', '-moz-', '-webkit-' ]
      tmp["#{i}#{prop}"] = val
    $(@).css tmp


  $.fn.ntEventCalendar = (opts) ->
    opts ?= {}

    @.each ->
      if !$(@).hasClass 'nt-kalendae'
        $(@).addClass('nt-kalendae').kalendae
          blackout      : -> true
          viewStartDate : opts.ym

      dates = opts.dates || []

      $(@).find('.k-days span:not(.k-out-of-month)')
      .removeClass('nt-k-start nt-k-end').click( (e) ->
        $tgt = $(e.target)
        $tgt.closest('.nt-kalendae').trigger 'dateclick', date: $tgt.data('date')
      ).each ->
        $self = $(@)
        date = $self.data 'date'
        cnt = 0

        for range in dates
          cnt++ if range[0] <= date <= range[1]
          break if cnt > 2

        $self.data 'cnt', cnt
        op = if cnt > 2 then .75 else cnt * .25
        $self.css 'background-color', "rgba(100, 100, 100, #{op})"

        $prev = $self.prev()
        prevcnt = parseInt($prev.data 'cnt')
        if cnt
          if !prevcnt
            $self.addClass 'nt-k-start'
          else if !$self.next(':not(.k-out-of-month)').get(0)
            $self.addClass 'nt-k-end'
        else if prevcnt
          $prev.addClass 'nt-k-end'

    $(@)

  $.fn.ntColorpicker = (opts) ->

    opts = $.extend {}, defaults.ntColorPicker, opts || {}

    opts.tWidth = opts.columns *
      (opts.cellWidth + (2 * opts.cellMargin))
    opts.tWidth += 2 if $.browser.msie

    opts.tHeight = Math.ceil(opts.colors.length / opts.columns) *
      (opts.cellHeight + (2 * opts.cellMargin))

    opts.el = @

    pluginId = ntPluginId 'colorpicker'

    click_callback = (event) ->
      unless $('div.color-picker').get(0)
        wWidth = $(window).width()
        left = $(@).offset().left
        # TODO: proper padding calculation
        if (left + opts.tWidth) > wWidth
          left = wWidth - opts.tWidth - 10

        colorPicker = $('<div class="color-picker" />').css
          'top'        : $(@).ntBottom()
          'left'       : left
          'width'      : "#{opts.tWidth}px"
          'height'     : "#{opts.tHeight}px"
          'border'     : opts.border
          'margin'     : '0px'
          'position'   : 'absolute',
          'z-index'    : 1000
          'margin-top' : '3px'
          'background-color' : 'white'

        $(opts.container || 'body').append colorPicker

        i = 0
        while i < opts.colors.length
          cell = $("<div id='#{opts.colors[i]}'/>").css
            'float'      : 'left'
            'width'      : "#{opts.cellWidth}px"
            'height'     : "#{opts.cellHeight}px"
            'margin'     : "#{opts.cellMargin}px"
            'cursor'     : 'pointer'
            'fontSize'   : '1px'
            'lineHeight' : "#{opts.cellHeight}px"
            'background-color': "##{opts.colors[i]}"

          colorPicker.append cell

          cell.click (e) ->
            if opts.onSelect? && $.isFunction opts.onSelect
              opts.onSelect @id

            if opts.target
              $(opts.target).css 'background-color', "##{@id}"
              $(opts.target).trigger 'colorchange', @id
            colorPicker.hide().remove()
            $('body').ntDetachEvent pluginId, 'click'
          i++

        $('body').ntAttachEvent pluginId, 'click', (event) ->
          unless $(event.target).closest(opts.el).get(0)
            $('div.color-picker').hide().remove()
            $('body').ntDetachEvent pluginId, 'click'

    if opts.defaultColor? && opts.target?
      $(opts.target).css 'background-color', "##{opts.defaultColor}"
      opts.onSelect opts.defaultColor if opts.onSelect

    $(@).ntAttachEvent pluginId, 'click', click_callback


  # TODO: jump to selected date on init
  #       jump to date while typing
  $.fn.ntDatepicker = (opts) ->
    dpClass = 'nt-datepicker'
    $targetEl = $(@)
    $dpDiv = $targetEl.next ".#{dpClass}"

    currWidth = $targetEl.width()
    pluginId = ntPluginId 'datepicker'

    opts = $.extend {},
      defaults.ntSharedDateTimePicker, defaults.ntDatePicker , opts || {}
    opts.currWidth = currWidth

    $ntPicker = $targetEl.ntPicker opts

    change = ->
      $(@container).parent().remove()
      selDate = @getSelectedAsDates()
      if selDate?
        selDate = selDate[0]
        val = opts.formatUIDate(opts.parseUIDate(selDate))
        $ntPicker.onChangeCB val
        $targetEl.html val
        $targetEl.blur()

    # This extend makes it possible to pass arguments to Kalendae
    opts = $.extend
      'subscribe' :
        'change': change
    , opts

    if !$dpDiv.get(0)
      $ntPicker.setValWithOrig $targetEl, $targetEl.html()

      $dpDiv = $("<div class=\"#{dpClass} nt-manualblur\"></div>")
      cal = new Kalendae $dpDiv.get(0), opts
      $('body').append $dpDiv

      $targetEl.ntDetachEvent pluginId, 'keyup'
      $targetEl.ntDetachEvent pluginId, 'paste'
      $targetEl.ntAttachEvent pluginId, 'keyup', $ntPicker.changeContent
      $targetEl.ntAttachEvent pluginId, 'paste', $ntPicker.changeContent

      $targetEl.ntDetachEvent pluginId, 'keydown'
      $targetEl.ntAttachEvent pluginId, 'keydown', (e) ->
        $el = $(e.target)
        if e.keyCode in [ 9, 13 ]
          e.preventDefault()

          d = opts.parseUIDate $el.html()
          if opts.isValidDate d
            $ntPicker.setValWithOrig $el, opts.formatUIDate(d)
            next = $el.nextAll('div[contenteditable="true"]')
            if next.length
              # This is not jQuery call
              next[0].focus()
              $(next[0]).ntSelectElementContents()
            else
              $el.blur()
          else
            $el.ntSelectElementContents()
            $ntPicker.showAlert()

          cal.setSelected opts.parseUIDate($(e.target).html())
        else if e.keyCode == 27
          $ntPicker.restoreValFromOrig $el
          $el.blur()

      $targetEl.ntDetachEvent pluginId, 'blur'
      $targetEl.ntAttachEvent pluginId, 'blur', (e) ->
        $el = $(e.target)
        d = opts.parseUIDate $el.html()
        if opts.isValidDate d
          $ntPicker.hideAlert()
          $dpDiv.remove()
          # Removing events
          $targetEl.ntDetachEvent pluginId, 'blur'
          $targetEl.ntDetachEvent pluginId, 'keyup'
          $targetEl.ntDetachEvent pluginId, 'paste'
          $targetEl.ntDetachEvent pluginId, 'keydown'
          $('body').ntDetachEvent pluginId, 'click'
          # Removing placeholder
          $ntPicker.cleanupPlaceHolder $targetEl
          # Setting original value
          $ntPicker.setValWithOrig $targetEl, opts.formatUIDate(d)
        else
          $el.ntSelectElementContents()
          $ntPicker.showAlert()

      $('body').ntDetachEvent pluginId, 'click'
      $('body').ntAttachEvent pluginId, 'click', (e) ->
        if !$(e.target).closest(".#{dpClass}").length &&
           e.target != $targetEl.get(0)
          $el = $(e.target)
          d = opts.parseUIDate $targetEl.html()
          if opts.isValidDate d
            $ntPicker.hideAlert()
            $dpDiv.remove()
            $targetEl.ntDetachEvent pluginId, 'blur'
            $targetEl.ntDetachEvent pluginId, 'keyup'
            $targetEl.ntDetachEvent pluginId, 'paste'
            $targetEl.ntDetachEvent pluginId, 'keydown'
            # Removing placeholder
            $ntPicker.cleanupPlaceHolder $targetEl
            # Setting original value
            $ntPicker.setValWithOrig $targetEl, opts.formatUIDate(d)
            # Removing events
            $('body').ntDetachEvent pluginId, 'click'
          else
            $ntPicker.restoreValFromOrig $targetEl
            $targetEl.blur()

    $dpDiv.css
      top: $targetEl.ntBottom()
      left: $targetEl.offset().left - parseInt($targetEl.width() / 2)

    $targetEl


  $.fn.ntTimepicker = (opts) ->
    tpClass = 'nt-timepicker'
    $targetEl = $(@)
    $tpDiv = $(@).next ".#{tpClass}"
    currWidth = $targetEl.width()

    opts = $.extend({},
      defaults.ntSharedDateTimePicker, defaults.ntTimePicker, opts || {})

    opts.tWidth = (opts.columns) *
      (opts.cellWidth + (2 * opts.cellMargin) +
       (opts.cellPaddingRight + opts.cellPaddingLeft)) + opts.padding
    opts.tWidth += 2 if $.browser.msie

    opts.tHeight = (opts.rows + 1) *
      (opts.cellHeight + (2 * opts.cellMargin) +
       opts.cellPaddingTop + opts.cellPaddingBottom + 1) + (opts.padding * 2)
    opts.currWidth = currWidth

    $ntPicker = $targetEl.ntPicker opts

    pluginId = ntPluginId 'timepicker'

    if !$tpDiv.get(0)
      left = $(@).offset().left
      $tpDiv = $("<div class=\"#{tpClass}\" />").css
        'top'              : $(@).ntBottom()
        'left'             : left
        'width'            : "#{opts.tWidth}px"
        'height'           : "#{opts.tHeight}px"
        'border'           : 'none'
        'padding'          : "#{opts.padding}px"
        'position'         : 'absolute',
        'z-index'          : 1000
        'margin-top'       : '3px'
        'background-color' : '#eee'
      $tpDiv.ntSetBorderRadius '5px'

      set_time = (m) ->
        valAttr = defaults.ntTimePicker.valAttr
        selAttr = defaults.ntTimePicker.selAttr
        typeAttr = defaults.ntTimePicker.typeAttr

        unSelOpts =
          'color'            : defaults.ntTimePicker.unSelColor
          'background-color' : defaults.ntTimePicker.unSelBg

        selOpts =
          'color'            : defaults.ntTimePicker.selColor
          'background-color' : defaults.ntTimePicker.selBg

        $('div',$tpDiv).removeAttr(selAttr).css unSelOpts

        d = moment m
        hour = d.hours()

        if hour >= 12
          $("div[#{typeAttr}='ampm'][#{valAttr}='pm']",$tpDiv)
            .attr(selAttr, 1)
            .css selOpts
        else
          $("div[#{typeAttr}='ampm'][#{valAttr}='am']",$tpDiv)
            .attr(selAttr, 1)
            .css selOpts

        hour += 12 if hour == 0
        hour -= 12 if hour > 12
        $("div[#{typeAttr}='h'][#{valAttr}='#{hour}']",$tpDiv)
          .attr(selAttr, 1)
          .css selOpts

        min = d.minutes()
        $("div[#{typeAttr}='m'][#{valAttr}='#{min}']",$tpDiv)
          .attr(selAttr, 1)
          .css selOpts

      click_callback = (e) ->
        e.stopPropagation()
        $el       = $(e.target)
        valAttr   = defaults.ntTimePicker.valAttr
        selAttr   = defaults.ntTimePicker.selAttr
        typeAttr  = defaults.ntTimePicker.typeAttr
        val       = $el.attr valAttr
        type      = $el.attr typeAttr
        className = defaults.ntTimePicker.types[type]

        $(".#{className}", $tpDiv).css
          'color'            : defaults.ntTimePicker.unSelColor
          'background-color' : defaults.ntTimePicker.unSelBg
        .removeAttr selAttr

        $el.css
          'color'            : defaults.ntTimePicker.selColor
          'background-color' : defaults.ntTimePicker.selBg
        .attr selAttr, 1

        min = parseInt(
          $("div[#{typeAttr}='m'][#{selAttr}='1']",$tpDiv)
          .attr(valAttr) || 0)

        hour = parseInt(
          $("div[#{typeAttr}='h'][#{selAttr}='1']",$tpDiv)
          .attr(valAttr) || 1)

        ampm =
          $("div[#{typeAttr}='ampm'][#{selAttr}='1']",$tpDiv).attr valAttr

        d = opts.parseUITime $targetEl.html()
        switch type
          when 'h'
            min = d.minutes()
          when 'm'
            hour = d.hours()

        # TODO: find best approach, probably without parsing
        d = opts.parseUITime "#{hour}:#{min} #{ampm}"

        opts.onSelect d if opts.onSelect? && $.isFunction opts.onSelect

        $targetEl.html opts.formatUITime(d)
        $targetEl.ntSelectElementContents()

        set_time d

      $('body').append $tpDiv

      cssOpts =
        'color'          : defaults.ntTimePicker.unSelColor
        'float'          : 'left'
        'width'          : "#{opts.cellWidth}px"
        'height'         : "#{opts.cellHeight}px"
        'margin'         : "#{opts.cellMargin}px"
        'cursor'         : 'pointer'
        'text-align'     : 'center'
        'lineHeight'     : "#{opts.cellHeight}px"
        'font-size'      : '11px'
        'background'     :  defaults.ntTimePicker.unSelBg
        'border'         : '1px solid transparent'
        'padding-top'    : "#{opts.cellPaddingTop}px"
        'padding-right'  : "#{opts.cellPaddingRight}px"
        'padding-bottom' : "#{opts.cellPaddingBottom}px"
        'padding-left'   : "#{opts.cellPaddingLeft}px"
        'border-radius'  : '3px'
        '-moz-border-radius' : '3px'
        '-webkit-border-radius' : '3px'

      for i in [ 1 .. opts.rows ]
        # hours
        hClass = defaults.ntTimePicker.types['h']
        cell = $("<div class=\"#{hClass}\" tp-type=\"h\" " +
                 "tp-val=\"#{i}\">#{i}</div>").css cssOpts
        $tpDiv.append cell
        cell.click (e) ->
          click_callback e

        #minutes
        mClass = defaults.ntTimePicker.types['m']
        v = defaults.ntTimePicker.times[i - 1]
        intV = parseInt v
        cell = $("<div class=\"#{mClass}\" tp-type=\"m\" tp-val=\"#{intV}\">#{v}</div>").css cssOpts
        cell.click (e) ->
          click_callback e
        $tpDiv.append cell

      # TODO: am/pm in lang
      apClass = defaults.ntTimePicker.types['ampm']
      for i in [ opts.amString, opts.pmString ]
        cell =
          $("<div class=\"#{apClass}\" tp-type=\"ampm\" tp-val=\"#{i}\">#{i}</div>").css cssOpts
        cell.css 'font-style', 'italic'

        cell.click (e) ->
          click_callback e
        $tpDiv.append cell

      set_time opts.parseUITime($targetEl.html()) if $targetEl.html()
      $ntPicker.setValWithOrig $targetEl, $targetEl.html()

      afterChangeContent = (e,el) ->
        $el = $(el)
        # Moving the picker to the entered date
        if e.keyCode not in [ 9, 13, 27 ]
          d = opts.parseUITime $el.html()
          if opts.isValidTime d
            set_time d

      opts.afterChangeContent = afterChangeContent

      $targetEl.ntDetachEvent pluginId, 'keyup'
      $targetEl.ntDetachEvent pluginId, 'paste'
      $targetEl.ntAttachEvent pluginId, 'keyup', $ntPicker.changeContent
      $targetEl.ntAttachEvent pluginId, 'paste', $ntPicker.changeContent

      $targetEl.ntDetachEvent pluginId, 'keydown'
      $targetEl.ntAttachEvent pluginId, 'keydown', (e) ->
        $el = $(e.target)
        if e.keyCode in [ 9, 13 ]
          e.preventDefault()
          d = opts.parseUITime $el.html()
          if opts.isValidTime d
            $ntPicker.setValWithOrig $el, opts.formatUITime(d)
            next = $el.nextAll('div[contenteditable="true"]')
            if next.length
              # This is not jQuery call
              next[0].focus()
              $(next[0]).ntSelectElementContents()
            else
              $el.blur()
            $targetEl.ntDetachEvent pluginId, 'blur'
            $targetEl.ntDetachEvent pluginId, 'keydown'
            $('body').ntDetachEvent pluginId, 'click'
            $tpDiv.remove()
          else
            $el.ntSelectElementContents()
            $ntPicker.showAlert()

        else if e.keyCode == 27
          $ntPicker.restoreValFromOrig $el
          $el.blur()
          $tpDiv.remove()

      $targetEl.ntDetachEvent pluginId, 'blur'
      $targetEl.ntAttachEvent pluginId, 'blur', (e) ->
        $el = $(e.target)
        d = opts.parseUITime $el.html()
        if opts.isValidTime d
          $el.html opts.formatUITime(d)
          $ntPicker.cleanupPlaceHolder $targetEl
          $ntPicker.hideAlert()
        else
          $ntPicker.showAlert()
          e.preventDefault()
          $targetEl.ntSelectElementContents()

      # Slightly different behaviour than at the datepicker
      $('body').ntAttachEvent pluginId, 'click', (e) ->
        if !$(e.target).closest(".#{tpClass}").length &&
           e.target != $targetEl.get(0)
          $el = $(e.target)
          d = opts.parseUITime $targetEl.html()
          if opts.isValidTime d
            $ntPicker.hideAlert()
            $tpDiv.remove()
            # Removing events
            $('body').ntDetachEvent pluginId, 'click'
            $targetEl.ntDetachEvent pluginId, 'keyup'
            $targetEl.ntDetachEvent pluginId, 'paste'
            $targetEl.ntDetachEvent pluginId, 'keydown'
            $targetEl.ntDetachEvent pluginId, 'blur'
            # Removing placeholder
            $ntPicker.cleanupPlaceHolder $targetEl
            $ntPicker.setValWithOrig $targetEl, opts.formatUITime(d)
            $targetEl.blur()
          else
            $ntPicker.showAlert()

    $targetEl


  $.fn.ntGetCaretPos = ->
    el = $(@).get(0)
    if el
      if el.selectionStart
        ret = el.selectionStart
      else if document.selection
        sel = document.selection.createRange()
        len = document.selection.createRange().text.length
        sel.moveStart 'character', -el.value.length
        ret = sel.text.length - len
    ret


  $.fn.ntSetCaretPos = (pos) ->
    el = $(@).get(0)
    if el.selectionStart
      el.selectionStart = pos
      el.selectionEnd = pos
    else if el.createTextRange
      sel = el.createTextRange()
      sel.moveStart 'character', pos
      sel.collapse()
      sel.moveEnd 'character', 0
      sel.select()
    $(@)


  $.fn.ntDndhover = (opts) ->
    if opts?.destroy
      $(@).off 'dragenter dragleave'
    else
      list = $()
      $(@).on 'dragenter', (e) ->
        $(@).trigger 'hoverstart' unless list.size()
        list = list.add(e.target)

      $(@).on 'dragleave', (e) ->
        list = list.not(e.target)
        $(@).trigger 'hoverend' unless list.size()

    $(@)


  $.fn.ntHlhits = (hits, cssclass, quotemeta, skipclass) ->
    # TODO: skipclass -> array
    $.error 'hlhits: missing cssclass.' unless cssclass?
    $.error 'hlhits: quotemeta is not a function.' unless _.isFunction quotemeta

    html = $(@).html()
    if _.isArray hits
      skipHtml = $(@).find(".#{skipclass}").html() if skipclass
      _.each hits, (kw) ->
        if kw?.length
          re = new RegExp '>([^<]*)?(\\b' + quotemeta(kw) + '\\w*)', 'ig'
          html = html.replace re, '>$1<span class="' + cssclass + '">$2</span>'
      $(@).html html
      $(@).find(".#{skipclass}").html(skipHtml) if skipclass
    $(@)


  $.fn.ntTooltip = (opts) ->
    if opts not in [ 'show', 'hide', 'destroy' ]
      opts = $.extend({}, defaults.ntTooltip, opts || {})
    $(@).popover opts
    $(@).popover('show') if opts.show
    $(@)


  $.fn.ntContEdPh = (opts) ->
    eventNs = 'ntph'
    cmd = opts
    opts = $.extend({}, defaults.ntContEdPh, opts || {})

    getCont = ->
      $(@).closest(".#{opts.contClass}")

    getPh = ->
      getCont.call(@).find(".#{opts.phClass}")

    adjustPh = ->
      $ph = getPh.call @
      if $(@).text().trim()
        $ph.hide()
      else
        $ph.show()

    destroyPh = ->
      for evt in [ 'keyup', 'paste', 'cut', 'showph', 'blur' ]
        $(@).off "#{evt}.#{eventNs}"
      getCont.call(@).replaceWith $(@)

    @each ->
      if cmd is 'destroy'
        destroyPh.call @
      else
        if !$(@).closest(".#{opts.contClass}").get(0)
          $cont = $('<div>').addClass(opts.contClass)
          for prop, val of opts.contClassStyle
            $cont.css(prop, val)
          $cont.css('overflow','visible') if opts?.contOverflowVisible
          $ph = $('<div>').addClass(opts.phClass).html(opts.ph)
          for prop, val of opts.phClassStyle
            $ph.css(prop, val)

          top = 0
          left = 0
          for prop in [ 'margin', 'padding' ]
            top += parseInt($(@).css("#{prop}-top"))
            left += parseInt($(@).css("#{prop}-left"))

          $ph.css
            top         : "#{top}px"
            left        : "#{left}px"
            'font-size' : $(@).css('font-size')

          $(@).wrap($cont).before($ph)

          $ph.click => $(@).trigger 'click'
          for evt in [ 'keyup', 'paste', 'cut', 'showph', 'blur' ]
            $(@).on "#{evt}.#{eventNs}", => adjustPh.call @

        adjustPh.call @
        getPh.call(@).hide() if opts?.hide?

    $(@)


  $(@)
)(jQuery)
