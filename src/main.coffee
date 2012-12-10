requirejs.config
  baseUrl: window.ntConfig.base + 'js/'

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

  # DEV ONLY
  urlArgs: 'nocache=' + (new Date()).getTime()

  # module level config
  config:
    i18n:
      # locale or navigator.language
      locale: window.ntConfig.locale

  # non-amd script dependencies
  shim:
    bootstrap       : [ 'jquery' ]
    jqueryui        : [ 'jquery' ]
    kalendae        : [ 'jquery', 'moment' ]
    jquerynt        : [ 'jqueryui', 'bootstrap', 'moment', 'kalendae', 'date' ]
    fullcalendar    : [ 'jqueryui' ]
    tinycolor       : [ 'jquery' ]

require [ 'app', 'jquery' ], (App) ->
  App.initialize()
