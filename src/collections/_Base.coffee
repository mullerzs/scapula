define (require) ->
  _ = require 'underscore'
  Backbone = require 'backbone'
  utils = require 'utils'

  Base = {}

  # ---- Collection -----------------------------------------------------------

  class Base.Collection extends Backbone.Collection
    constructor: (models, options) ->
      super
      options ?= {}

      utils.adoptProps @, options, 'baseUrl', 'url', 'urlParams', 'autoSave',
        'modelDefaults', 'rankAttr', 'parentUrl'

      url = utils.getProp @, 'url'
      @url = @baseUrl + url if @baseUrl && url

      if @rankAttr
        if !@comparator
          @comparator = (item) => item.get @rankAttr
        @sort()
        @on 'add', @sortItem, @

    reset: (models) =>
      if @rankAttr
        if _.isArray(models)
          if models.length && _.some(models, (model) => !model[@rankAttr]?)
            model[@rankAttr] = i + 1 for model, i in models
        else if _.isObject(models) && !models[@rankAttr]?
          models[@rankAttr] = 1
      super

    saveNewModels: =>
      newModels = @filter (model) -> model.isNew()
      if newModels
        dfds = _.map newModels, (model) ->
          model.save null, url: '/api' + model.urlRoot
        $.when.apply(@, dfds).then ->
          $.Deferred().resolve newModels
      else
        $.Deferred().resolve []

    syncModelsTo: (coll, opts) =>
      return unless coll
      opts ?= {}
      attr = opts.attr || 'id'
      # NOTE: _pale means the model has partial refs
      addObjs = _.filter coll.toJSON(), (obj) =>
        !obj['_pale'] && obj[attr] not in @pluck(attr)
      removeModels = if opts.remove then @filter (model) ->
        model.get(attr) not in coll.pluck(attr)

      @add addObjs if addObjs.length
      @remove removeModels if removeModels?.length

    fetch: =>
      @deferData = super.done( =>
        @prepareSync()
        @trigger 'fetch'
      ).fail =>
        @trigger 'fetchError'

    fetchOnce: (opts) =>
      @deferData || @fetch(opts)

    prepareSync: =>
      @each (model) -> model.prepareSync()

    addItem: (modelAttrs, opts) =>
      opts ?= {}
      modelAttrs = [ modelAttrs ] unless _.isArray modelAttrs

      attrs = opts.chkExAttrs
      if attrs
        attrs = [ attrs ] unless _.isArray attrs
        models = []

        for model in modelAttrs
          filt = @filter (item) ->
            for attr in attrs
              res = item.get(attr) is model[attr]
              break if res
            res

          models.push model unless filt.length
      else
        models = modelAttrs

      if models.length
        if @noSync
          @add models, opts
        else if @parentUrl
          @addRel models, opts
        else
          @create model, _.extend parse: true, opts for model in models

    sortItem: (item, list, opts) =>
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

    _handleRel: (action, models, opts) =>
      @[action](models, opts) unless opts?.saveOnly
      models = [ models ] unless _.isArray models
      ids = _.pluck _.filter(models, (model) -> model?.id), 'id'
      if ids.length
        method = if action is 'add' then 'create' else 'delete'
        Backbone.sync.call @, method, @, _.extend {}, opts, ids: ids
      else
        $.Deferred().resolve()

    addRel: (models, opts) =>
      @_handleRel 'add', models, opts

    removeRel: (models, opts) =>
      @_handleRel 'remove', models, opts

    remove: =>
      super
      @trigger 'empty', @ if @length == 0

    # NOTE: return value is an array of models!
    # USAGE EXAMPLES:
    #   collection.search '"John Doe" superhero', 'name',
    #     tags: flds: 'descr'
    #   collection.search 'john', [ 'name', 'email' ],
    #     tags: flds: 'descr', kwords: 'superhero'
    search: (kws, flds, children) =>
      kws = utils.extractKeywords kws unless _.isArray kws
      flds = [ flds ] if flds? && !_.isArray flds

      @filter (item) ->
        kwords = _.clone kws

        if flds && kwords
          tmp = []
          for kword in kwords
            for fld in flds
              pat = new RegExp '\\s' + $.ntQuoteMeta(kword), 'i'
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

  # ---- Return ---------------------------------------------------------------

  Base
