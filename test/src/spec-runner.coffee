define (require) ->
  specs =
    _baseCollectionSpec : require '../js/specs/_baseCollectionSpec'
    _baseViewSpec       : require '../js/specs/_baseViewSpec'
    jqueryNtSpec        : require '../js/specs/jqueryNtSpec'
    utilsSpec           : require '../js/specs/utilsSpec'

  ret =
    initialize : ->
      specs[spec].test() for spec of specs

      jasmine.getEnv().addReporter new jasmine.TrivialReporter()
      jasmine.getEnv().execute()

  ret
