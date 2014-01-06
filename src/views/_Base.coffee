define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  ModelBinder = require 'modelbinder'
  Handlebars = require 'handlebars'
  lang = require 'lang'
  utils = require 'utils'
  vent = require 'vent'

  require 'hbshelpers'

  Base = {}

  # ---- View -----------------------------------------------------------------

  class Base.View extends Backbone.View
    getClass: => @_class

    notifier: _.extend {}, Backbone.Events

    notifierPub: =>
      args = Array.prototype.slice.call arguments
      @notifier.trigger.apply @notifier, args if args[0]?

    notifierSub: (event, callback) =>
      if _.isObject event
        events = event
      else
        (events = {})[event] = callback

      @listenTo @notifier, eventName, events[eventName] for eventName of events

    sharedStatus: _.extend {}

    adoptOptions: =>
      utils.adoptProps @, @options, [].slice.call arguments

    constructor: (options) ->
      @setDomId = true
      @options = options || {}
      super

      id = @$el.attr('id')
      @embedded = true if !@embedded? && id && $('#' + id).get(0)
      @$el.attr('id', @model.modelid()) if !id? && @model && @setDomId

      @$el.data 'backbone-view', @

      if _.isFunction @initTplVars
        @tplvars ?= {}
        @initTplVars()

      if _.isFunction @initModelDomBindings
        @modelDomBindings ?= {}
        if !@modelBindOnRender?
          @modelBindOnRender = if @options.modelBindOnRender?
            @options.modelBindOnRender
          else
            true
        @initModelDomBindings()

      # initialize view, DOM, notifier events
      for type in [ 'Events', 'DomEvents', 'NotifierSub' ]
        func = 'init' + type
        if _.isFunction @[func]
          isDomEvents = type is 'DomEvents'
          @events ?= {} if isDomEvents
          @[func]()
          @delegateEvents() if isDomEvents

      @dim = @options.dim if @options.hasOwnProperty 'dim'

      if @dim
        @notifierSub 'cont:adjust:height', @adjustHeight
        @listenTo @, 'render', @adjustHeight

    addTplVar: (varname, value) =>
      if _.isObject varname
        vars = varname
      else
        (vars = {})[varname] = value

      @tplvars ?= {}
      _.extend @tplvars, vars

    delTplVar: (varname) =>
      delete @tplvars[varname]

    extendTplVar: (varname, value) =>
      if _.isObject varname
        vars = varname
      else
        (vars = {})[varname] = value

      for v of vars
        @tplvars[v] ?= if _.isArray vars[v] then [] else {}

        if _.isArray(@tplvars[v]) && _.isArray(vars[v])
          @tplvars[v].push elem for elem in vars[v]
        else if _.isObject(@tplvars[v]) && _.isObject(vars[v])
          _.extend @tplvars[v], vars[v]
        else
          utils.throwError 'Incompatible types!', 'extendTplVar'

    addModelDomBinding: (fld, binding) =>
      if _.isObject fld
        bindings = fld
      else
        (bindings = {})[fld] = binding

      @modelDomBindings ?= {}
      _.extend @modelDomBindings, bindings

    delModelDomBinding: (flds) =>
      if @modelDomBindings
        flds = [ flds ] unless _.isArray flds
        delete @modelDomBindings[fld] for fld in flds

    toggleModelDomBindings: (set) =>
      if set
        if @el && @model && @modelDomBindings
          @modelBinder = new ModelBinder() unless @modelBinder
          @modelBinder.bind @model, @$el, @modelDomBindings
      else if @modelBinder
        @modelBinder.unbind()

    initEvents: =>
      if @model
        @listenTo @model, 'destroy', @remove
        @listenTo @model, 'fetch', @render

    addDomEvent: (selector, callback) =>
      if _.isObject selector
        domEvents = selector
      else
        (domEvents = {})[selector] = callback

      _.extend @events, domEvents

    delDomEvent: (selector) =>
      delete @events[selector]

    initDomEvents: =>
      if @model?.collection?.rankAttr
        @addDomEvent 'sortItem', (e, opts) =>
          e.stopPropagation()
          @sortItem opts

    sortItem: (opts) =>
      if @model?.collection?.rankAttr
        @model.collection.sortItem @model, @model.collection, opts
      else
        utils.throwError 'No sorted collection found for model', 'sortError'

    renderTpl: =>
      @template = Handlebars.compile @template unless _.isObject @template

      if @langvars
        vars = []
        istrs = {}
        for langvar of @langvars
          strs = lang.__ivars[langvar]
          vars = vars.concat strs
        for v in vars
          istrs[v] = utils.interpolate lang[v], vars: @langvars

      args = lang: _.extend {}, lang, istrs

      if @model
        args.modelid = @model.modelid()
        args.model = if _.isFunction @encodeModel
          @encodeModel()
        else
          @model.toJSON()
      args.vars = @tplvars if @tplvars

      if @partials
        Handlebars.registerPartial pname, ptext for pname, ptext of @partials

      @$el.html @template args

    render: =>
      if @template
        @beforeRender() if _.isFunction @beforeRender
        @rendered = false
        @renderTpl()
        @afterRender() if _.isFunction @afterRender
        @toggleModelDomBindings true if @modelBindOnRender
        @rendered = true
        @trigger 'render'
      else
        utils.throwError 'No template specified for the view'

      @

    close: (opts) =>
      @trigger 'close'
      @closed = true
      @beforeClose() if _.isFunction(@beforeClose) && !opts?.skipBefore
      @stopListening()
      @unbind()
      @toggleModelDomBindings false

      if !opts?.noremove
        if @embedded
          @$el.empty()
          @undelegateEvents()
        else
          @$el.remove()

        # NOTE: this workaround is because of fading remove
        @parent.trigger 'closeitem' if @parent?.collection

    delete: =>
      if @model
        @parent?.collection?.remove @model
        @model.destroy()

    remove: =>
      @beforeClose() if _.isFunction @beforeClose
      @$el.fadeOut =>
        @close skipBefore: true

    adjustHeight: (opts) =>
      return unless @el
      contHeight = opts?.contHeight
      # TODO: better dim selector handling
      if @el.id is 'container' && opts?.init
        addh = 0
        for cssdef in [ 'padding-top', 'padding-bottom',
                        'margin-top', 'margin-bottom' ]
          addh += parseInt @$el.css cssdef
        contHeight ?= $(window).height()
        contHeight -= addh
        @$el.height contHeight
        @sharedStatus.contHeight = contHeight
        contPtop = parseInt(@$el.css 'padding-top')
        @sharedStatus.contOffset = @$el.offset().top + contPtop
        @notifierPub 'cont:adjust:height', contHeight: contHeight
      else if @dim
        contHeight ?= @sharedStatus.contHeight
        return unless contHeight

        elems = _.map @dim, (val,key) -> $(key)

        _.each @dim, (pars, elem) =>
          return unless pars?
          $obj = if elem then @$el.find(elem) else @$el

          perc = (pars.height?.match /^(\d+)%$/)?[1]
          if !perc
            perc = (pars.maxHeight?.match /^(\d+)%$/)?[1]
            max = true

          if perc
            h = contHeight
            if !pars.noOffset
              $offObj = if pars.selfOffset then $obj else @$el
              contOffset = @sharedStatus.contOffset || 0
              if @el.id isnt 'container'
                h -= $offObj.offset().top - contOffset
            if pars.subtract
              $subBase = if pars.subtractBase
                @$el.find(pars.subtractBase)
              else
                @$el
              $subBase.find(pars.subtract).each ->
                return unless $(@).is ':visible'
                subh = $(@).outerHeight true
                for $el in elems
                  isChild = false
                  $inspected = $(@)
                  $el.each -> isChild = true if $(@).closest($inspected).length
                  elh = $el.outerHeight()
                  subh -= elh if isChild && elh < subh
                h -= subh
            h = parseInt h * perc / 100

            padding = $obj.outerHeight() - $obj.height()
            h -= padding
            h = 0 if h < 0

            if max
              $obj.css 'max-height', h + 'px'
            else
              h = pars.minHeight if pars.minHeight && pars.minHeight > h
              $obj.height h

            $obj.css 'min-height', pars.minHeight + 'px' if pars.minHeight

          overflow = pars.overflow || 'auto'
          $obj.css 'overflow-y', overflow
          $obj.css '-webkit-overflow-scrolling', 'touch'

        @trigger 'heightchange'


  # ---- Default Empty List Placeholder ---------------------------------------

  class Base.EmptyListPhView extends Base.View
    className: 'nt-empty-list-ph'

    initialize: ->
      @template = '<p>{{vars.msg}}</p>'
      @msg = @options.msg

    initTplVars: =>
      @msg = lang[@msg] if lang[@msg]
      @addTplVar msg: @msg if @msg

  # ---- ParentView -----------------------------------------------------------

  class Base.ParentView extends Base.View
    render: =>
      @closeChildren()
      super

    getChild: (name) =>
      @children?[name]

    storeChild: (view, name, opts) =>
      @children ?= {}
      if _.isObject view
        if name
          key = name
        else if view.model
          key = view.model.cid
        else
          utils.throwError 'No child name specified and no available model'
      else
        utils.throwError 'Invalid view given for storeChild'

      view.parent = @
      @children[key] = view

      view.render() if opts?.render

    storeChildren: (obj, opts) =>
      @storeChild view, name, opts for name, view of obj

    renderChildren: =>
      _.each @children, (child) ->
        child.render()

    closeChildren: (opts) =>
      _.each @children, (child) ->
        child.close opts

      @children = {}

    close: =>
      @closed = true
      @closeChildren noremove: true
      super

    createModal: (modalClass, opts, callbacks) =>
      return if @closed
      opts ?= {}
      delay = opts.delay
      opts = _.omit opts, 'delay'

      childId = opts.childId
      if @closed ||
         (childId && @getChild(childId) && !@getChild(childId).closed)
        return

      delete opts.childId

      modalView = new modalClass opts
      if _.isObject callbacks
        for cname of callbacks
          @listenTo modalView, cname, callbacks[cname]

      showModal = =>
        childId ?= "modal#{modalView.cid}"
        @storeChild modalView, childId, render: true

      if delay
        setTimeout showModal, delay
      else
        showModal()

  # ---- CollectionView -------------------------------------------------------

  class Base.CollectionView extends Base.ParentView
    constructor: ->
      super
      @adoptOptions 'itemSelector', 'itemCont', 'limitItems', 'emptyViewCont',
        'emptyHideSelector', 'emptyMsg', 'emptyFilterMsg', 'EmptyView',
        'EmptyViewOpts'

      @$itemCont = @$el unless @template && @itemCont
      @itemSelector ?= 'div'

    initCollectionEvents: =>
      if @collection
        @listenTo @collection, 'add', @addItemView
        @listenTo @collection, 'remove', @removeItemView
        @listenTo @collection, 'reset', @render

    initEvents: =>
      @initCollectionEvents()
      @listenTo @, 'closeitem', @showEmptyView
      @listenTo @, 'closeitem', @changeVisibleItems if @options.obsVisItems

    buildItemView: (item) =>
      ItemView = @options.ItemView || @ItemView
      if ItemView
        opts = _.extend {}, @ItemViewOpts, @options.ItemViewOpts
        opts.model = item
        itemView = new ItemView opts
        @storeChild itemView
      else
        utils.throwError 'No ItemView specified for the CollectionView'

      itemView

    addItemView: (item, list, opts) =>
      @closeEmptyView restore: true

      itemView = @buildItemView item

      $el = itemView.render().$el
      idx = if opts?.at? then opts.at else @collection.indexOf(item)
      children = @$itemCont.children @itemSelector
      if idx? && idx < children.length
        $el.insertBefore children.eq(idx)
      else
        @appendItemView itemView

      if !opts?.hide && !opts?.render && @options.showOnAdd
        @showItems[item.id] = 1 if @showItems
      else if opts?.hide || (@showItems && !@showItems[item.id])
        $el.addClass 'hide'

      @afterAddItemView itemView, opts if _.isFunction @afterAddItemView

      @trigger 'additemview', itemView, opts
      @changeVisibleItems() if !opts?.render && @options.obsVisItems

    appendItemView: (itemView) =>
      @$itemCont.append itemView.$el

    removeItemView: (item) =>
      itemView = @children[item.cid]
      if itemView
        itemView.remove()
        delete @children[item.cid]
      @afterRemoveItemView itemView if _.isFunction @afterRemoveItemView

      @trigger 'removeitemview', itemView

    render: (items, opts) =>
      if @asyncRender
        @stopAsyncRender()
        @itemRenderTo = []

      items = @collection.models unless items?
      items = items.models unless _.isArray items

      @closeEmptyView()

      if @collection.deferData && @collection.deferData.state() isnt 'rejected'
        @collection.deferData.done => @renderItems items, opts
      else
        @renderItems items, opts

      @

    renderItems: (items, opts) =>
      @beforeRender() if _.isFunction @beforeRender
      @rendered = false

      @closeChildren noremove: true
      @deferRender = $.Deferred() if @asyncRender
      @$el.empty()

      len = items.length
      @renderTpl() if @template && (len || @emptyViewCont)

      if len
        if @asyncRender
          to_offset = if _.isFinite(@asyncRender) then @asyncRender else 0

        for item, idx in items
          addopts = render: true
          addopts.hide = true if @limitItems && idx > @limitItems - 1
          if @asyncRender
            @itemRenderTo.push setTimeout =>
              @addItemView item, {}, addopts
              @deferRender.resolve() if idx == len
            , ++idx * 10 + to_offset
          else
            @addItemView item, {}, addopts
      else
        @deferRender.resolve() if @asyncRender

      @showEmptyView items, opts if !len || @emptyViewCont

      if @asyncRender
        @deferRender.done @_postRender
      else
        @_postRender()

      @

    _postRender: =>
      @afterRender() if _.isFunction @afterRender
      @rendered = true
      @trigger 'render'
      @changeVisibleItems() if @options.obsVisItems

    renderTpl: =>
      super
      @$itemCont = @$el.find(@itemCont) if @itemCont

    stopAsyncRender: =>
      if @itemRenderTo?.length
        clearTimeout i for i in @itemRenderTo

    showEmptyView: (items, opts) =>
      len = items?.length ? @collection.length
      return if @emptyViewVisible || len ||
                !(@emptyMsg || @EmptyView || @EmptyViewOpts)

      @EmptyView ?= Base.EmptyListPhView

      emptyMsg = if opts?.emptyMsg?
        opts.emptyMsg
      else if opts?.filter && @emptyFilterMsg?
        @emptyFilterMsg
      else
        @emptyMsg
      eopts = if emptyMsg? then msg: emptyMsg else {}
      eopts = _.extend {}, @EmptyViewOpts, eopts

      @emptyView = new @EmptyView eopts
      @emptyViewVisible = true

      emptyViewCont = @$el
      if @emptyViewCont
        emptyViewCont = if _.isObject @emptyViewCont
          @emptyViewCont
        else
          @$(@emptyViewCont)
      @$(@emptyHideSelector).hide() if @emptyHideSelector
      emptyViewCont.html @emptyView.render().$el
      @trigger 'showempty'

    closeEmptyView: (opts) =>
      if @emptyViewVisible
        @emptyView.close()
        delete @emptyViewVisible
        @renderTpl() if @template && opts?.restore
        @trigger 'hideempty'

    close: =>
      @stopAsyncRender()
      @closeEmptyView()
      super

    _filter: (kword, flds, subs) =>
      # NOTE: renderOnFilter gives empty list when search has no kwords/subs
      items = if !@options.renderOnFilter || kword || subs
        @collection.search kword, flds, subs
      else
        []

      if @options.renderOnFilter
        @render items, if kword || subs then filter: true
      else
        cnt = 0
        @showItems = {}
        _.each items, (item) =>
          @showItems[item.id] = 1 if !@limitItems? || cnt < @limitItems
          cnt++

        _.each @children, (child) =>
          child.$el.toggleClass 'hide', !@showItems[child.model.id]

      @trigger 'filter'
      if @$itemCont && @options.obsVisItems && !@options.renderOnFilter
        @changeVisibleItems()
      items

    visibleItemCnt: =>
      @$itemCont.find('>*').not('.hide').length

    changeVisibleItems: =>
      @trigger 'changevisibleitems', @visibleItemCnt()

    getItemAt: (opts) =>
      opts ?= {}
      if opts.at
        children = @$itemCont.children(@itemSelector)
        @$(children.get(opts.at))?.data 'backbone-view'

  # ---- Return ---------------------------------------------------------------

  Base
