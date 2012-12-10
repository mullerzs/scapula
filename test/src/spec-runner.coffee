define (require) ->
  specs =
    utilsSpec              : require '../js/specs/utilsSpec'
    _baseViewSpec          : require '../js/specs/_baseViewSpec'
    _baseCollectionSpec    : require '../js/specs/_baseCollectionSpec'

  ret =
    initialize : ->
      specs[spec].test() for spec of specs

      jasmine.getEnv().addReporter new jasmine.TrivialReporter()
      jasmine.getEnv().execute()

  ret
