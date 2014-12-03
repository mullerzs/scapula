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
      @_unSynced = !!opts?.unSynced
      @noSync = !!opts?.noSync

      @autoSave = opts.autoSave if opts?.autoSave?
      autoSaveTimeout = utils.getConfig('autoSaveTimeout') || 50

      @on 'sync', => delete @_unSynced

      @on 'change', (model, copts) =>
        if !@isNew() && !@_unSynced && !@noSync && !@collection?.noSync &&
            !copts?.init
          changed = @changedAttributes() || {}
          delete changed[key] for key of changed when @isInternalAttr key

          return if _.isEmpty(changed) || 'id' in _.keys(changed)

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

    isInternalAttr: (attr) =>
      attr? && (attr.match(/^_/) || attr in (@_internalAttrs || []))

    internalAttrs: =>
      ret = []
      for attr of @attributes
        ret.push attr if @isInternalAttr attr
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

      if !opts?.unset
        for attr, value of attrs
          continue unless value?
          if @_dateAttrs && attr in @_dateAttrs
            attrs[attr] = utils.dbDateToIso value
          else if @_integerAttrs && attr in @_integerAttrs
            attrs[attr] = parseInt value
          else if @_floatAttrs && attr in @_floatAttrs
            attrs[attr] = parseFloat value
          else if @_boolAttrs && attr in @_boolAttrs && !_.isBoolean value
            intval = parseInt value
            attrs[attr] = value && isNaN(intval) || intval

      super attrs, opts

    urlParams: =>
      utils.getProp(@, 'urlRootParams') ||
        utils.getProp(@collection, 'urlParams')

    save: =>
      clearTimeout @_saveTo if @_saveTo
      if !@isNew() && !@isDirty()
        $.Deferred().resolve {}
      else
        super

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

    dirtyAttrs: (opts) =>
      attrs = @_dirty
      @_dirty = {} if opts?.clear
      @toJSON attrs: _.keys(attrs)

    invertAttr: (attr) =>
      @set attr, !@get attr

    fetch: =>
      @deferData = super.done( =>
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
        ret[attr] = utils.isoToDbDate ret[attr] for attr in @_dateAttrs

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
      opts ?= {}

      if !opts.unset && !opts.noChildren
        for cname, props of @collections
          coll = @[cname]

          if !coll
            copts = _.extend relType: 'id', props.options
            coll = @[cname] = new props.constructor null, copts
            coll.parentModel = @
            coll.url = @childUrl coll.url if coll.url

            if props.setAttr
              coll.on 'change reset', =>
                (cattrs = {})[cname] = coll.toJSON()
                @set cattrs, noChildren: true

          if attrs.hasOwnProperty cname
            if attrs[cname]?
              coll.reset attrs[cname],
                _.extend parse: true, props.resetOpts, _.pick opts, 'init'
            else
              @[cname] = null

      super attrs, opts

    childUrl: (url) =>
      => utils.getProp(@, 'url') + url

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