require [ 'config' ], ->
  require [ 'jquerynt' ], ->
    require [ 'app' ], (app) ->
      app.initialize()
