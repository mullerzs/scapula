define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  utils = require 'utils'

  Base = {}

  # ---- Model ----------------------------------------------------------------

  class Base.Model extends Backbone.Model
    constructor: (attributes, opts) ->
      super
      @_dirty = {}

      @autoSave = opts.autoSave if opts?.autoSave?
      autoSaveTimeout = utils.getConfig('autoSaveTimeout') || 50

      @on 'change', =>
        if @_syncPrepared
          changed = _.omit (@changedAttributes() || {}), @internalAttrs()

          return if _.isEmpty changed

          _.extend @_dirty, changed

          autoSave = if @collection?.autoSave?
            @collection.autoSave
          else
            @autoSave

          if autoSave
            clearTimeout @_saveTo
            @_saveTo = setTimeout =>
              @save()
            , autoSaveTimeout

    internalAttrs: =>
      ret = []
      for attr of @attributes
        if attr.match(/^_/) || attr in @_internalAttrs
          ret.push attr
      ret

    _setArgs: (key, val, opts) =>
      if _.isObject(key) || !key?
        attrs = key
        opts = val
      else
        (attrs = {})[key] = val

      attrs = attrs.attributes if attrs instanceof Base.Model

      [attrs, opts]

    set: (key, val, opts) =>
      [attrs, opts] = @_setArgs key, val, opts

      if !opts?.unset && @_dateAttrs
        for attr of attrs
          if attr in @_dateAttrs
            attrs[attr] = utils.dbDateToIso8601 attrs[attr]

      super attrs, opts

    url: =>
      url = super
      if @collection?.parentUrl
        utils.getProp(@collection, 'parentUrl') + url
      else
        url

    urlParams: =>
      utils.getProp(@, 'urlRootParams') ||
        utils.getProp(@collection, 'urlParams')

    save: =>
      clearTimeout @_saveTo if @_saveTo
      ret = if !@isNew() && !@isDirty()
        $.Deferred().resolve {}
      else
        super

      ret.done => @prepareSync()

    setDirty: (attrs) =>
      return unless attrs?
      attrs = [ attrs ] unless _.isArray attrs
      @_dirty[attr] = @get(attr) for attr in attrs

    isDirty: =>
      _.keys(@_dirty).length

    saveAttrs: (attrs, opts) =>
      return unless attrs?

      if $.isPlainObject attrs
        @set attrs, opts
        attrs = _.keys attrs

      @_dirty = {} if opts?.reset
      @setDirty attrs
      @save()

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
        ret = _.omit ret, @internalAttrs()

      if opts?.attrs?.length
        ret = _.pick ret, opts.attrs

      if @_dateAttrs
        ret[attr] = utils.iso8601ToDbDate ret[attr] for attr in @_dateAttrs

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

    set: (key, val, opts) =>
      [attrs, opts] = @_setArgs key, val, opts

      if !opts?.unset && !opts?.noChildren
        for cname, props of @collections
          coll = @[cname]

          if !coll
            coll = @[cname] = new props.constructor()
            coll.parentModel = @

            if props.noSync
              coll.noSync = true
            else
              url = coll.url
              if url
                if !props.fullSync
                  coll.parentUrl = => utils.getProp(@, 'url')
                coll.url = => utils.getProp(@, 'url') + url

            if props.setAttr
              coll.on 'change reset', =>
                (cattrs = {})[cname] = coll.toJSON()
                @set cattrs, noChildren: true

          if attrs.hasOwnProperty cname
            if attrs[cname]?
              coll.reset attrs[cname], { silent: true, parse: true }
            else
              @[cname] = null

      super attrs, opts

    syncChildTo: (cname, coll, opts) ->
      child = @[cname]
      if child
        child.syncModelsTo coll, opts
        @set cname, child.toJSON() unless @collections[cname].setAttr

    toJSON: (opts) =>
      ret = super

      if opts?.children
        children = {}

        for cname, props of @collections
          return if props.setAttr ||
            (opts.attrs?.length && cname not in opts.attrs)

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
