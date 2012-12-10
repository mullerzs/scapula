define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  ModelBinder = require 'modelbinder'
  Hogan = require 'hogan'
  lang = require 'lang'
  utils = require 'utils'

  Base = {}

  # ---- View -----------------------------------------------------------------

  class Base.View extends Backbone.View
    notifier: _.extend {}, Backbone.Events

    notifierPub: =>
      args = Array.prototype.slice.call arguments
      @notifier.trigger.apply @notifier, args if args[0]?

    notifierSub: (event, callback) =>
      events = {}
      if _.isObject event
        events = event
      else
        events[event] = callback

      @bindTo @notifier, eventName, events[eventName] for eventName of events

    sharedStatus: _.extend {}

    constructor: ->
      @bindings = []
      super

      id = @$el.attr('id')
      @embedded = true if !@embedded? && id && $('#' + id).get(0)
      @$el.attr('id',@model.modelid()) if !id? && @model

      @$el.data 'backbone-view', @

      if _.isFunction @initTplVars
        @tplvars ?= {}
        @initTplVars()

      if _.isFunction @initModelDomBindings
        @modelDomBindings ?= {}
        if !@modelBindOnRender?
          @modelBindOnRender = if @options?.modelBindOnRender?
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

      @dim = @options?.dim if @options?.hasOwnProperty 'dim'

      if @dim
        @notifierSub 'cont:adjust:height', @adjustHeight, @
        @bindTo @, 'render', @adjustHeight, @

    addTplVar: (varname, value) =>
      vars = {}
      if _.isObject varname
        vars = varname
      else
        vars[varname] = value

      @tplvars ?= {}
      @tplvars[v] = vars[v] for v of vars

    delTplVar: (varname) =>
      delete @tplvars[varname]

    extendTplVar: (varname, value) =>
      vars = {}
      if _.isObject varname
        vars = varname
      else
        vars[varname] = value

      for v of vars
        if !@tplvars?
          @tplvars[v] = if _.isArray vars[v] then [] else {}

        if _.isArray(@tplvars[v]) && _.isArray(vars[v])
          @tplvars[v].push elem for elem in vars[v]
        else if _.isObject(@tplvars[v]) && _.isObject(vars[v])
          _.extend @tplvars[v], vars[v]
        else
          utils.throwError 'Incompatible types!', 'extendTplVar'

    addModelDomBinding: (fld, binding) =>
      bindings = {}
      if _.isObject fld
        bindings = fld
      else
        bindings[fld] = binding

      @modelDomBindings[s] = bindings[s] for s of bindings

    delModelDomBinding: (fld) =>
      delete @modelDomBindings[fld]

    toggleModelDomBindings: (set) =>
      if set
        if @model && @modelDomBindings
          @modelBinder = new ModelBinder() unless @modelBinder
          @modelBinder.bind @model, @$el, @modelDomBindings
      else if @modelBinder
        @modelBinder.unbind()

    initEvents: =>
      if @model
        @bindTo @model, 'destroy', @remove, @
        @bindTo @model, 'fetch', @render, @

    addDomEvent: (selector, callback) =>
      domEvents = {}
      if _.isObject selector
        domEvents = selector
      else
        domEvents[selector] = callback

      @events[sel] = domEvents[sel] for sel of domEvents

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

    bindTo: (obj, eventName, callback, context) =>
      context = context || @
      obj.on eventName, callback, context

      @bindings.push
        obj       : obj
        eventName : eventName
        callback  : callback
        context   : context

    unbindAll: (opts) =>
      opts ?= {}
      rmbindings = []
      _.each @bindings, (binding) ->
        if !opts.obj || opts.obj && opts.obj is binding.obj
          binding.obj.off binding.eventName, binding.callback, binding.context
          rmbindings.push binding if opts.obj

      if !opts.obj
        @bindings = []
      else if rmbindings.length
        @bindings = _.difference @bindings, rmbindings

    renderTpl: =>
      @template = Hogan.compile @template unless typeof @template is 'object'

      if @langvars
        vars = []
        istrs = {}
        for langvar of @langvars
          strs = lang.__ivars[langvar]
          vars = vars.concat strs
        for v in vars
          istrs[v] = utils.interpolate lang[v], vars: @langvars

      args =
        lang   : _.extend {}, lang, istrs

        encode : -> (text, render) ->
          utils.encodeHtml render(text)

        fmt    :
          pct  : -> (text, render) ->
            utils.formatPct parseFloat render(text)
          date : -> (text, render) ->
            utils.formatDate render(text)
          time : -> (text, render) ->
            utils.formatTime render(text)
          datetime : -> (text, render) ->
            utils.formatDateTime render(text)

      if @model
        args.modelid = @model.modelid()
        args.model = if _.isFunction @encodeModel
          @encodeModel()
        else
          @model.toJSON()
      args.vars = @tplvars if @tplvars
      partials = @partials || {}

      @$el.html @template.render args, partials

    render: =>
      if @template
        @beforeRender() if _.isFunction @beforeRender
        @renderTpl()
        @afterRender() if _.isFunction @afterRender
        @toggleModelDomBindings true if @modelBindOnRender
        @rendered = true
        @trigger 'render'
      else
        utils.throwError 'No template specified for the view'

      @

    renderDom: =>
      @render()
      @afterDomAdd() if _.isFunction @afterDomAdd

      @

    close: (opts) =>
      @$('[data-original-title]').tooltip 'hide'

      @beforeClose() if _.isFunction(@beforeClose) && !opts?.skipBefore
      @unbindAll()
      @unbind()
      @toggleModelDomBindings false

      if @embedded
        @$el.empty()
        @undelegateEvents()
      else if !opts?.noremove
        @$el.remove()

      # NOTE: this workaround is because of fading remove
      @parent.trigger 'closeitem' if @parent?.collection
      @closed = true

    delete: =>
      if @model
        @parent?.collection?.remove @model
        @model.destroy()

    remove: =>
      @beforeClose() if _.isFunction @beforeClose
      @$el.fadeOut =>
        @close skipBefore: true

    adjustHeight: (contHeight, opts) =>
      # TODO: better dim selector handling
      if @el.id is 'container' && opts?.init
        @$el.height contHeight
        @sharedStatus.contHeight = contHeight
        contPtop = parseInt(@$el.css 'padding-top')
        @sharedStatus.contOffset = @$el.offset().top + contPtop
        @notifierPub 'cont:adjust:height', contHeight
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
              h -= $offObj.offset().top - contOffset unless @el.id is 'container'
            if pars.subtract
              $subBase = if pars.subtractBase then @$el.find(pars.subtractBase) else @$el
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

        @trigger 'heightchange'

  # ---- Default Empty List Placeholder ---------------------------------------

  class Base.EmptyListPhView extends Base.View
    className: 'nt-empty-list-ph'

    initialize: ->
      @template = '<p>{{vars.msg}}</p>'
      @msg = @options?.msg

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
      _.each obj, (view, name) =>
        @storeChild view, name, opts
      @trigger 'storechildren'

    renderChildren: =>
      _.each @children, (child) ->
        child.render()

    closeChildren: (opts) =>
      _.each @children, (child) ->
        child.close opts

      @children = {}

    close: =>
      @closeChildren noremove: true
      super

  # ---- CollectionView -------------------------------------------------------

  class Base.CollectionView extends Base.ParentView
    constructor: ->
      super
      if !@itemSelector
        @itemSelector = @options?.itemSelector || 'div'
      @$itemCont = @$el unless @template && @itemCont
      @limitItems = @options?.limitItems
      @emptyViewCont = @options?.emptyViewCont

      for opt in [ 'EmptyView', 'EmptyViewOpts', 'emptyMsg' ]
        @[opt] = @options[opt] if @options?[opt]

    initCollectionEvents: =>
      if @collection
        @bindTo @collection, 'add', @addItemView, @
        @bindTo @collection, 'remove', @removeItemView, @
        @bindTo @collection, 'reset', @render, @

    initEvents: =>
      @initCollectionEvents()
      @bindTo @, 'closeitem', @showEmptyView, @

    buildItemView: (item) =>
      ItemView = @options?.ItemView || @ItemView
      if ItemView
        opts = _.extend {}, @ItemViewOpts, @options?.ItemViewOpts
        opts.model = item
        itemView = new ItemView opts
        @storeChild itemView
      else
        utils.throwError 'No ItemView specified for the CollectionView'

      itemView

    addItemView: (item, list, opts) =>
      @closeEmptyView restore: true

      itemView = @buildItemView(item)

      $el = itemView.render().$el
      idx = if opts?.at? then opts.at else opts?.index
      children = @$itemCont.children @itemSelector
      if idx? && idx < children.length
        $el.insertBefore children.eq(idx)
      else
        @appendItemView itemView
      $el.addClass 'hide' if opts?.hide

      itemView.afterDomAdd opts if _.isFunction itemView.afterDomAdd

      @afterAddItemView itemView, opts if _.isFunction @afterAddItemView

      @trigger 'additemview', itemView, opts

    appendItemView: (itemView) =>
      @$itemCont.append itemView.$el

    removeItemView: (item) =>
      itemView = @children[item.cid]
      if itemView
        itemView.remove()
        delete @children[item.cid]
      @afterRemoveItemView itemView if _.isFunction @afterRemoveItemView

      @trigger 'removeitemview', itemView

    render: (items) =>
      items = @collection.models unless items?
      items = items.models unless _.isArray items

      @closeEmptyView()

      if @collection.deferData && @collection.deferData.state() isnt 'rejected'
        @collection.deferData.done => @renderItems items
      else
        @renderItems items

      @

    renderItems: (items) =>
      @beforeRender() if _.isFunction @beforeRender

      @closeChildren noremove: true
      @deferRender = $.Deferred() if @asyncRender
      @$el.empty()

      len = items.length
      @renderTpl() if @template && (len || @emptyViewCont)

      if len
        if @asyncRender
          _(items).each (item, idx) =>
            opts = render: true
            opts.hide = true if @limitItems && idx > @limitItems - 1
            setTimeout =>
              @addItemView item, {}, opts
              @deferRender.resolve() if idx == len
            , ++idx
        else
          _(items).each (item, idx) =>
            opts = render: true
            opts.hide = true if @limitItems && idx > @limitItems - 1
            @addItemView item, {}, opts
      else
        @deferRender.resolve() if @asyncRender
      @showEmptyView() if !len || @emptyViewCont

      isAfter = _.isFunction @afterRender

      if @asyncRender
        @deferRender.done =>
          @afterRender() if isAfter
          @rendered = true
          @trigger 'render'
      else
        @afterRender() if isAfter
        @rendered = true
        @trigger 'render'

      @

    renderTpl: =>
      super
      @$itemCont = @$el.find(@itemCont) if @itemCont

    showEmptyView: =>
      return if @emptyViewVisible || @collection.length ||
                !(@emptyMsg || @EmptyView || @EmptyViewOpts)

      @EmptyView ?= Base.EmptyListPhView
      if !@EmptyViewOpts
        @EmptyViewOpts = if @emptyMsg? then msg: @emptyMsg else {}

      @emptyView = new @EmptyView _.clone(@EmptyViewOpts)
      @emptyViewVisible = true

      emptyViewCont = @$el
      if @emptyViewCont
        emptyViewCont = if _.isObject @emptyViewCont
          @emptyViewCont
        else
          @$(@emptyViewCont)
      emptyViewCont.html @emptyView.render().$el

    closeEmptyView: (opts) =>
      if @emptyViewVisible
        @emptyView.close()
        delete @emptyViewVisible
        @renderTpl() if @template && opts?.restore

    close: =>
      @closeEmptyView()
      super

    _filter: (kword, flds, subs) =>
      items = @collection.search kword, flds, subs
      showitems = {}
      _.each items, (item) ->
        showitems[item.id] = 1

      cnt = 0
      _.each @children, (child) =>
        if showitems[child.model.id] && (!@limitItems? || cnt < @limitItems)
          child.$el.removeClass 'hide'
          ++ cnt
        else
          child.$el.addClass 'hide'

      @trigger 'filter'
      items

  # ---- TabView --------------------------------------------------------------

  class Base.TabView extends Base.ParentView
    # NOTE: uses bootstrap nav tabs structure
    constructor: ->
      super
      @tabs = @options?.tabs || [] unless @tabs

    initDomEvents: =>
      @addDomEvent 'click .nt-tabs a', @clickTab

    clickTab: (e) =>
      e.preventDefault()
      @loadTab e.target.id

    loadTab: (tabid) =>
      utils.throwError 'No tabid specified for loadTab' unless tabid

      seltab = tab for tab in @tabs when tab.id == tabid

      actView = @getChild 'actView'
      if actView
        return if seltab.id == @actTab
        $('#' + @actTab).removeClass 'active'
        actView.close()

      @actTab = seltab.id
      $('#' + @actTab).addClass 'active'
      Backbone.history.navigate seltab.url if actView && seltab.url

      opts = @TabViewOpts || {}
      opts.model = @model if @model
      actView = new seltab.view opts
      @storeChild actView, 'actView', render: true
      @notifierPub 'cont:adjust:height'

  # ---- Return ---------------------------------------------------------------

  Base
