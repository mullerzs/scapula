define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  utils = require 'utils'

  Base = {}

  # ---- Model ----------------------------------------------------------------

  class Base.Model extends Backbone.Model
    constructor: (attributes, options) ->
      super
      @_dirty = {}

      @autoSave = options.autoSave if options?.autoSave?
      autoSaveTimeout = utils.getConfig('autoSaveTimeout') || 50

      @on 'change', =>
        if @_syncPrepared
          changed = @changedAttributes() || {}

          for attr of changed
            delete changed[attr] if utils.isInternalAttr attr
          return unless _.keys(changed).length

          _.extend @_dirty, changed

          autoSave = if @collection?.autoSave?
            @collection.autoSave
          else
            @autoSave

          if autoSave
            clearTimeout @saveTo
            @saveTo = setTimeout =>
              @save()
            , autoSaveTimeout

    set: (key, value, options) =>
      if _.isObject(key) || !key?
        attrs = key
        options = value
      else
        attrs = {}
        attrs[key] = value

      options ?= {}
      return @ unless attrs
      attrs = attrs.attributes if attrs instanceof Base.Model
      if options.unset
        attrs[attr] = null for attr of attrs

      if @dateAttrs
        for attr of attrs
          if attr in @dateAttrs
            attrs[attr] = utils.dbDateToIso8601 attrs[attr]

      super attrs, options

    url: =>
      url = super
      if @collection?.parentUrl
        utils.getProp(@collection, 'parentUrl') + url
      else
        url

    urlParams: =>
      pars = utils.getProp(@, 'urlRootParams') || utils.getProp(@collection, 'urlParams')

    save: =>
      clearTimeout @saveTo if @saveTo
      ret = if !@isNew() && !@isDirty()
        $.Deferred().resolve {}
      else
        super

      ret.done => @prepareSync()

    isDirty: =>
      _.keys(@_dirty).length

    saveAttrs: (attrs) =>
      return unless attrs?

      attrs = [ attrs ] unless _.isArray attrs
      @_dirty = {}
      for attr in attrs
        @_dirty[attr] = @get attr

      @save()

    undelete: =>
      if @get 'deleted'
        @collection?.undeleteItem id: @id
        @set deleted: ''
        ret = @saveAttrs 'deleted'
      else
        ret = $.Deferred().resolve()

      ret

    prepareSync: =>
      @_syncPrepared = true

    dirtyAttrs: (opts) =>
      attrs = @_dirty
      @_dirty = {} if opts?.clear
      @toJSON attrs: _.keys(attrs)

    fetch: =>
      @deferData = super.done( =>
        @prepareSync()
        @trigger 'fetch'
      ).fail =>
        @trigger 'fetchError'

    modelid: =>
      @id || @cid

    toJSON: (opts) =>
      ret = super

      if opts?.skipInternal
        for attr of ret
          delete ret[attr] if utils.isInternalAttr attr

      filtered = opts?.attrs?.length > 0

      if filtered
        for attr of ret
          delete ret[attr] unless _.include opts.attrs, attr

      if @dateAttrs
        ret[attr] = utils.iso8601ToDbDate ret[attr] for attr in @dateAttrs

      ret

    duplicate: =>
      attrs = @cloneAttrs()
      new @constructor attrs

    cloneAttrs: (opts) =>
      ret = @toJSON opts
      delete ret.id if ret?.id
      ret

  # ---- ParentModel ----------------------------------------------------------

  class Base.ParentModel extends Base.Model
    collections: {}

    set: (key, value, options) =>
      if _.isObject(key) || !key?
        attrs = key
        options = value
      else
        attrs = {}
        attrs[key] = value

      options ?= {}
      return @ unless attrs
      attrs = attrs.attributes if attrs instanceof Base.Model
      if options.unset
        attrs[attr] = null for attr of attrs

      if !options.noChildren
        _.each @collections, (props,cname) =>
          coll = @[cname]

          # TODO: create only if needed (radio/checkbox)
          if !coll
            coll = @[cname] = new props.constructor()
            coll.parentModel = @

            if props.noSync
              coll.noSync = true
            else
              url = coll.url
              if url
                coll.parentUrl = => utils.getProp(@, 'url')
                coll.url = => utils.getProp(@, 'url') + url

            if props.setAttr
              coll.on 'change', =>
                cattrs = {}
                cattrs[cname] = coll.toJSON()
                @set cattrs, noChildren: true

          if attrs.hasOwnProperty cname
            if attrs[cname]?
              coll.reset attrs[cname], silent: true
            else
              @[cname] = null

      super attrs, options

    toJSON: (opts) =>
      ret = super

      if opts?.children
        filtered = opts?.attrs?.length > 0
        children = {}

        _.each @collections, (props,cname) =>
          return if props.setAttr || (filtered && !_.include opts.attrs, cname)

          coll = @[cname]
          if coll
            arr = []
            for item, i in coll
              model = coll.at(i)
              if model.id
                arr[i] = if opts.children is 'id'
                  model.id
                else
                  model.attributes

            children[cname] = arr

        ret = _.extend ret, children

      ret

  # ---- Return ---------------------------------------------------------------

  Base
