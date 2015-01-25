define (require) ->
  mvconv = require 'mvconv'

  module = {}

  module._generic = (selector, elAttribute, converter) ->
    selector    : selector
    elAttribute : elAttribute
    converter   : converter

  module.bool = (selector, elAttribute) ->
    module._generic selector, elAttribute, mvconv.bool

  module.class = (selector, converter) ->
    module._generic selector, 'class', converter

  module.boolClass = (selector, cname) ->
    module.class selector, (dir, val) ->
      if dir is 'ModelToView'
        if val then cname else ''

  module.html = (selector) ->
    module._generic selector, 'html', mvconv.html

  module.float = (selector, elAttribute) ->
    module._generic selector, elAttribute, mvconv.float

  module.float0 = (selector, elAttribute) ->
    module._generic selector, elAttribute, mvconv.float0

  module
