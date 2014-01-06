define (require) ->
  utils = require 'utils'
  moment = require 'moment'

  ret =
    test: ->
      describe 'utils', ->
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

        it 'calcRank', ->
          out = utils.calcRank()
          expect(out).toEqual 1

          out = utils.calcRank 1, 2
          expect(out).toEqual 1.5

          out = utils.calcRank null, 4.5
          expect(out).toEqual 2.25

          out = utils.calcRank 5.25
          expect(out).toEqual 6.25

          expect ->
            utils.calcRank null, '1'
          .toThrow new Error 'Invalid parameters for calcRank'

          expect ->
            utils.calcRank { a: 'b' }
          .toThrow new Error 'Invalid parameters for calcRank'

        it 'display smart date', ->
          # today
          time = moment().hours(16).minutes(0)
          expect(utils.formatDateTimeSmart(time)).toEqual '4pm'

          # other day this month
          time.date(if time.date() == 16 then 1 else 16)
          expect(utils.formatDateTimeSmart(time))
            .toEqual "#{time.format('D MMM')} #{time.format('ha')}"

          # other year in january
          time.year(time.year() + 2).month(0)
          expect(utils.formatDateTimeSmart(time))
            .toEqual "#{time.format('D MMM YYYY')} #{time.format('ha')}"

          # within 6 months
          time = moment().minutes(0).subtract('months', 5)
          expect(utils.formatDateTimeSmart(time))
            .toEqual "#{time.format('D MMM')} #{time.format('ha')}"

          # outside 6 months
          time = moment().minutes(0).subtract('months', 7)
          expect(utils.formatDateTimeSmart(time))
            .toEqual "#{time.format('D MMM YYYY')} #{time.format('ha')}"

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

        describe 'interpolate tests', ->
          str = 'I have a #{dream}, #{n thing|things}'

          it 'extracts vars correctly', ->
            expect(utils.extractVars(str)).toEqual [ 'dream', 'n' ]

          it 'interpolates strings / plurals', ->
            intpol = utils.interpolate str, vars: dream: 'pencil', n: 1
            expect(intpol).toEqual 'I have a pencil, 1 thing'

            intpol = utils.interpolate str, vars: dream: 'hero', n: 2
            expect(intpol).toEqual 'I have a hero, 2 things'

  ret
