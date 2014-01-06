require [ '../../js/config' ], ->
  require [ 'jquery' ], ->
    require [ '../test/js/spec-runner'
              '../test/js/libs/jasmine-jquery'
              '../test/js/libs/sinon' ], (specRunner) ->
      specRunner.initialize()
