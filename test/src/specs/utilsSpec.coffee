define (require) ->
  utils = require 'utils'

  ret =
    test: ->
      describe 'utils', ->
        decPattern = "< Test >  test\n&"
        encPattern = '&lt; Test &gt;&nbsp;&nbsp;test<br/>&amp;'

        it 'decodeHtml Basic', ->
          out = utils.decodeHtml encPattern
          expect(out).toEqual decPattern

        it 'decodeHtml Spaces & Newlines', ->
          out = utils.decodeHtml '   Test  &nbsp;test<br/> <br>'
          expect(out).toEqual "Test  test"

        it 'encodeHtml Basic', ->
          out = utils.encodeHtml decPattern
          expect(out).toEqual encPattern

        it 'encodeHtml Spaces & Newlines', ->
          out = utils.encodeHtml "  Test\ntest Test\n"
          expect(out).toEqual '&nbsp;&nbsp;Test<br/>test Test<br/>&nbsp;'

        it 'chkEmail', ->
          for str in [ 'jetli123@hero.org',
                       'HiroyukiSanada@Ninja86.jp',
                       'van-damme.dolph_lundgren@some.uni-soldier.com' ]
            out = utils.chkEmail str
            expect(out).toBeTruthy()

          for str in [ 'hello', 'hello@', 'hello@baby', '@baby' ]
            out = utils.chkEmail str
            expect(out).not.toBeTruthy()

        it 'extractKeywords', ->
          teststrs =
            '"John Doe " superhero " Jack  " ' : 'John Doe,Jack,superhero'
            ' hello   baby  " "hero " '        : '"hero,hello,baby'

          for input of teststrs
            output = utils.extractKeywords input
            expect(output.join(',')).toEqual teststrs[input]

        it 'throwError', ->
          expect ->
            utils.throwError 'test error'
          .toThrow new Error 'test error'

        describe 'ntConfig tests', ->
          beforeEach ->
            window.ntConfig =
              foo   : '/n/'
              hello : [ 'A', 'B' ]

          it 'getConfig', ->
            cfg = utils.getConfig 'foo'

            expect(cfg).toEqual '/n/'

            cfg = utils.getConfig 'hello'

            expect(cfg).toEqual [ 'A', 'B' ]

          it 'setConfig', ->
            utils.setConfig 'foo', mycfg: 34

            expect(window.ntConfig.foo).toEqual mycfg: 34

            utils.setConfig
              hello1 : 13
              hello2 : [ 'hi', 23 ]

            expect(window.ntConfig.hello1).toEqual 13
            expect(window.ntConfig.hello2).toEqual [ 'hi', 23 ]
            expect(window.ntConfig.hello).toEqual [ 'A', 'B' ]

        describe 'ntStatus tests', ->
          beforeEach ->
            window.ntStatus =
              foo   : '/n/'
              hello : [ 'A', 'B' ]

          it 'getStatus', ->
            cfg = utils.getStatus 'foo'

            expect(cfg).toEqual '/n/'
            expect(window.ntStatus.foo).toBeUndefined()

            cfg = utils.getStatus 'hello'

            expect(cfg).toEqual [ 'A', 'B' ]
            expect(window.ntStatus.hello).toBeUndefined()

          it 'setStatus', ->
            utils.setStatus 'foo', mycfg: 34

            expect(window.ntStatus.foo).toEqual mycfg: 34

            utils.setStatus
              hello1 : 13
              hello2 : [ 'hi', 23 ]

            expect(window.ntStatus.hello1).toEqual 13
            expect(window.ntStatus.hello2).toEqual [ 'hi', 23 ]
            expect(window.ntStatus.hello).toEqual [ 'A', 'B' ]

          it 'delStatus', ->
            utils.delStatus 'foo'

            expect(window.ntStatus.foo).toBeUndefined()

        it 'quoteMeta', ->
          str = utils.quotemeta()

          expect(str).toEqual ''

          str = utils.quotemeta('A1.\\+*?[^]$()')

          expect(str).toEqual 'A1\\.\\\\\\+\\*\\?\\[\\^\\]\\$\\(\\)'

  ret
