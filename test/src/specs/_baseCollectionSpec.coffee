define (require) ->
  _ = require 'underscore'
  BaseModels = require 'basemodels'
  BaseCollections = require 'basecollections'
  utils = require 'utils'

  class SubModel extends BaseModels.ParentModel

  class SubCollection extends BaseCollections.Collection

  class TestModel extends BaseModels.ParentModel
    collections:
      subs:
        constructor: SubCollection

  class TestCollection extends BaseCollections.Collection
    model: TestModel

  data = [
    id    : 'U1'
    name  : 'John Doe'
    email : 'john@earth.com'
    subs  : [
      descr: 'Hello'
    ,
      descr: 'Baby'
    ]
  ,
    id    : 'U2'
    name  : 'Jane Wright'
    email : 'jane@girls.gov'
    subs  : [ descr: 'Baby' ]
  ,
    id    : 'U3'
    name  : 'Jack Ripper'
    email : 'johann@ripme.edu'
  ]

  chkSearch = (res, exp) ->
    ids = _.pluck res, 'id'
    expect(ids).toEqual exp

  ret =
    test: ->
      # ============================
      describe '_BaseCollection', ->
        beforeEach ->
          @testCollection = new TestCollection data

        # -------------------
        describe 'search', ->
          it 'searches correctly with empty keywords', ->
            res = @testCollection.search '', 'name'
            chkSearch res, [ 'U1', 'U2', 'U3' ]

            res = @testCollection.search [], 'name'
            chkSearch res, [ 'U1', 'U2', 'U3' ]

            res = @testCollection.search '', 'name', subs: flds: 'descr', kwords: ''
            chkSearch res, [ 'U1', 'U2', 'U3' ]

            res = @testCollection.search [], 'name', subs: flds: 'descr', kwords: []
            chkSearch res, [ 'U1', 'U2', 'U3' ]

          it 'searches correctly with default keywords', ->
            res = @testCollection.search 'jo', [ 'name', 'email' ]
            chkSearch res, [ 'U1', 'U3' ]

            res = @testCollection.search 'ohn', 'name'
            chkSearch res, []

          it 'searches correctly also in children with default keywords', ->
            res = @testCollection.search '"John Doe" Baby', 'name',
              subs: flds: 'descr'
            chkSearch res, [ 'U1' ]
          
          it 'searches correctly also in children with children specific keywords', ->
            res = @testCollection.search 'j', 'name', subs: flds: 'descr', kwords: 'ba'
            chkSearch res, [ 'U1', 'U2' ]

            res = @testCollection.search [ 'j' ], 'name', subs: flds: 'descr', kwords: [ 'ba' ]
            chkSearch res, [ 'U1', 'U2' ]

            res = @testCollection.search '', 'name', subs: flds: 'descr', kwords: 'baby hello'
            chkSearch res, [ 'U1' ]

            res = @testCollection.search [ '' ], 'name', subs: flds: 'descr', kwords: [ 'baby', 'hello' ]
            chkSearch res, [ 'U1' ]
  ret

