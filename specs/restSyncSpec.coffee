define (require) ->
  BaseModels = require 'basemodels'
  BaseCollections = require 'basecollections'
  utils = require 'utils'

  class SubModel extends BaseModels.Model

  class SubCollection extends BaseCollections.Collection
    model: SubModel

  class TestModel extends BaseModels.ParentModel
    collections:
      subs:
        constructor: SubCollection

  ret =
    test: ->
      # =======================
      describe '_BaseModel', ->
        # -----------------
        describe 'POST', ->
          beforeEach ->
            utils.setConfig 'client_id_name', 'client_id_'

            @testModel = new TestModel
              desc : 'hello'
              subs : [
                desc: 'sub1'
              ,
                desc: 'sub2'
              ]
            @testModel.url = '/things'

            resp =
              success : 'great'
              content :
                id         : 12
                client_id_ : @testModel.cid
                desc       : 'hello'
                flags      : 2
                subs       : [
                  id         : 31
                  client_id_ : @testModel.subs.at(0).cid
                  desc       : 'sub1a'
                ,
                  id         : 32
                  client_id_ : @testModel.subs.at(1).cid
                  desc       : 'sub2a'
                ]

            @server = sinon.fakeServer.create()
            @server.respondWith 'POST', '/api/things', [
              200
            ,
              'Content-Type': 'application/json'
            ,
              JSON.stringify(resp)
            ]
            @server.autoRespond = true
            @server.autoRespondAfter = 1000

          afterEach ->
            @server.restore()

          it 'create -> gets ids properly', ->
            require [ 'restsync' ], =>
              @testModel.save()

            waitsFor ->
              @testModel.id == 12 &&
                @testModel.subs.at(0).id == 31 &&
                @testModel.subs.at(1).id == 32
            , 1500

  ret
