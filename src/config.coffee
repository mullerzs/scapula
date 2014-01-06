requirejs.config
  baseUrl: window.ntConfig.base + 'js/'

  paths:
    text            : 'libs/text'
    i18n            : 'libs/i18n'
    jquery          : 'libs/jquery'
    jquerynt        : 'jquery-nt'
    underscore      : 'libs/underscore'
    backbone        : 'libs/backbone'
    modelbinder     : 'libs/backbone-modelbinder'
    handlebars      : 'libs/handlebars'
    base64          : 'libs/base64'
    moment          : 'libs/moment'
    date            : 'libs/date'

    tpls            : '../tpls'
    baseviews       : 'views/_Base'
    basemodels      : 'models/_Base'
    basecollections : 'collections/_Base'

  # DEV ONLY
  urlArgs: 'nocache=' + (new Date()).getTime()

  # module level config
  config:
    moment:
      noGlobal: true

    i18n:
      # locale or navigator.language
      locale: window.ntConfig.locale

  # non-amd script dependencies
  shim:
    jquerynt: [ 'jquery' ]

    backbone:
      deps: [ 'underscore', 'jquery' ]
      exports: 'Backbone'

    underscore:
      exports: '_'

    handlebars:
      exports: 'Handlebars'
