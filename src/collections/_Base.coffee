define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  utils = require 'utils'
  ajax = require 'ajax'

  Base = {}

  # ---- Collection -----------------------------------------------------------

  class Base.Collection extends Backbone.Collection
    constructor: (models, options) ->
      super
      options ?= {}
      for prop in [ 'baseUrl', 'url', 'urlParams', 'autoSave', 'modelDefaults',
                    'rankAttr', 'parentUrl' ]
        @[prop] = options[prop] if options[prop]?

      url = utils.getProp @, 'url'
      @url = @baseUrl + url if @baseUrl && url

      if @rankAttr
        @comparator = (item) => item.get @rankAttr
        @sort()

      # TODO: proper place for defaults
      @on 'add', (item, list, opts) =>
        @sortItem(item, list, opts) if @rankAttr
        item.set @modelDefaults, silent: true if @modelDefaults && item.isNew()
      , @

      @on 'remove', (item) =>
        @trigger 'change', @
        if @_deleted_items && !item.get 'deleted'
          del_item = item.toJSON children: true
          del_item.deleted = '1'
          @_deleted_items.push del_item

      @on 'destroy', (item) =>
        @purgeItem id: item.id if @parentUrl || item.get 'deleted'

    sort: =>
      super
      @trigger 'sort'

    fetch: =>
      @deferData = super.done( =>
        @each (model) -> model.prepareSync()
        @trigger 'fetch'
      ).fail =>
        @trigger 'fetchError'

    fetchOnce: (opts) =>
      @deferData || @fetch(opts)

    getById: (id) =>
      @get(id) || @getByCid(id)

    indexById: (id) =>
      model = @getById id
      @indexOf model

    # NOTE: return value is an array of models!
    # USAGE EXAMPLES:
    #   collection.search '"John Doe" superhero', 'name',
    #     tags: flds: 'descr'
    #   collection.search 'john', [ 'name', 'email' ],
    #     tags: flds: 'descr', kwords: 'superhero'
    search: (kws, flds, children) =>
      kws = utils.extractKeywords kws unless _.isArray kws
      flds = [ flds ] if flds? && !_.isArray flds

      # NOTE: search in deleted items
      onlyDeleted = false
      tags = children?.tags
      if tags && tags.flds is 'id' &&
          _.isArray(tags.kwords) && '_deleted' in tags.kwords
        onlyDeleted = true
        tags.kwords.splice _.indexOf(tags, '_deleted'), 1

      if @_deleted_items
        if onlyDeleted
          if !@_live_items
            @_live_items = @toJSON children: true
            @reset @_deleted_items
        else if @_live_items
          @reset @_live_items
          @_live_items = null

      ret = @filter (item) ->
        return false if onlyDeleted && !item.get('deleted')

        kwords = _.clone kws

        if flds && kwords
          tmp = []
          for kword in kwords
            for fld in flds
              pat = new RegExp '\\s' + utils.quotemeta(kword), 'i'
              val = item.get fld
              res = pat.test ' ' + val if val?
              if res
                tmp.push kword
                break

          kwords = _.difference kwords, tmp

        children_ok = true

        if _.isObject children
          for cname of children
            child = children[cname] || {}
            cflds = child.flds
            continue unless cflds? && item[cname] instanceof Backbone.Collection

            ckwords = child.kwords
            nonEmpty = !_.isArray(ckwords) && !_.isString(ckwords) || ckwords.length

            if ckwords? && nonEmpty
              ckws = if _.isArray ckwords
                ckwords
              else
                utils.extractKeywords ckwords

              for ckw in ckws
                cmodels = item[cname].search ckw, cflds
                if !cmodels.length
                  children_ok = false
                  break

              break unless children_ok
            else
              tmp = []
              for kword in kwords
                cmodels = item[cname].search kword, cflds
                tmp.push kword if cmodels.length

              kwords = _.difference kwords, tmp

        !kwords.length && children_ok

      ret

    addItem: (modelAttrs, opts) =>
      opts ?= {}
      modelAttrs = [ modelAttrs ] unless _.isArray modelAttrs

      attrs = opts.chkExAttrs
      if attrs
        attrs = [ attrs ] unless _.isArray attrs
        models = []

        list = @_live_items || @models

        for model in modelAttrs
          filt = _.filter list, (item) =>
            for attr in attrs
              val = if @_live_items then item[attr] else item.get(attr)
              res = val is model[attr]
              break if res
            res

          delete model.deleted
          models.push model unless filt.length
      else
        models = modelAttrs

      if models.length
        if @_live_items
          @_live_items = @_live_items.concat models
          if !@noSync && @parentUrl
            @addRel models, skipAdd: true
            # TODO: native collection deleted mode add?
        else if @noSync
          @add models, opts
        else if @parentUrl
          @addRel models, opts
        else
          @create model, opts for model in models

    updateItem: (opts) =>
      opts ?= {}
      attrs = _.clone opts.attrs if opts.attrs

      if attrs
        item = @getById attrs.id
        if item
          delete attrs.id
          item.set attrs
        else if @_live_items
          for item, i in @_live_items
            if item.id is attrs.id
              @_live_items[i] = attrs
              break

    sortItem: (item,list,opts) =>
      if item
        at = if _.isNumber opts.at then opts.at else null
        if at?
          idx = @indexOf(item)
          curr = item.get 'rank' # curr is undefined for new items
          if idx != at || !curr?
            idx = if idx > at || !curr? then at - 1 else at
            prev = @at(idx)?.get 'rank' if idx >= 0
            next = @at(idx + 1)?.get 'rank' if idx < @length
        else if @length > 1
          prev = @at(@length - 2)?.get 'rank'

        rank = utils.calcRank prev, next
        item.set 'rank', rank
        @sort silent: true if at?
      else
        utils.throwError 'No model item specified for sortItem'

    purgeItem: (opts) =>
      opts ?= {}
      if @_deleted_items && opts.id
        delitem = _.find @_deleted_items, (item) => item.id is opts.id
        if delitem
          @_deleted_items.splice _.indexOf(@_deleted_items, delitem), 1

      delitem

    undeleteItem: (opts) =>
      opts ?= {}
      delitem = @purgeItem id: opts.id
      if delitem
        if @_live_items
          delete delitem.deleted
          @_live_items.push delitem
          @remove @getById opts.id
        else
          @add delitem

      delitem

    addRel: (models,opts) =>
      ret = @add models, opts unless opts.skipAdd
      if models
        models = [ models ] unless _.isArray models
        opts ?= {}
        opts.ids = _.pluck models, 'id'
        # TODO: id check
        Backbone.sync.call @, 'create', @, opts
      ret

    remove: =>
      super
      @trigger 'empty', @ if @length == 0

  # ---- Return ---------------------------------------------------------------

  Base
