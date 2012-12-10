requirejs.config
  baseUrl: '../js'
  # TODO: paths from one source
  paths:
    text            : 'libs/text'
    i18n            : 'libs/i18n'
    image           : 'libs/image'
    jquery          : 'libs/jquery'
    jqueryui        : 'libs/jquery-ui'
    jquerynt        : 'jquery-nt'
    underscore      : 'libs/underscore'
    backbone        : 'libs/backbone'
    modelbinder     : 'libs/backbone-modelbinder'
    bootstrap       : 'libs/bootstrap'
    hogan           : 'libs/hogan'
    base64          : 'libs/base64'
    fullcalendar    : 'libs/fullcalendar'
    kalendae        : 'libs/kalendae'
    moment          : 'libs/moment'
    date            : 'libs/date'
    tinycolor       : 'libs/tinycolor'
    tpls            : '../tpls'
    baseviews       : 'views/_Base'
    basemodels      : 'models/_Base'
    basecollections : 'collections/_Base'

  # non-amd script dependencies
  shim:
    jqueryui        : [ 'jquery' ]
    jquerynt        : [ 'jquery', 'kalendae', 'moment', 'date' ]
    bootstrap       : [ 'jquery' ]
    fullcalendar    : [ 'jqueryui' ]
    tinycolor       : [ 'jquery' ]

require [ 'jquery' ], ->
  require [ '../test/js/spec-runner'
            '../test/js/libs/jasmine-jquery'
            '../test/js/libs/sinon'
            '../test/js/libs/jquery-simulate-drag-sortable' ], (specRunner) ->
    specRunner.initialize()
