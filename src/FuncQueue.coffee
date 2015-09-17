define (require) ->
  class FuncQueue
    constructor: (opts) ->
      @queue = []
      @opts = opts || {}

    enqueue: (fn, opts = {}) =>
      @dequeue() if opts.replace ? @opts.replace
      @queue.push
        func     : -> fn.apply opts.scope, opts.params
        deferred : opts.deferred
      @run() if @queue.length == 1
     
    dequeue: =>
      @queue.pop() if @queue.length > 1

    done: =>
      @queue.shift()
 
    run: =>
      return unless @queue.length

      result = @queue[0].func.call()
      if $.isPlainObject(result) && $.isFunction(result.always)
        result.always =>
          if (!(@opts.skipWhenNext && @queue.length > 1) ||
              @opts.stopOnError && result.state() is 'rejected') &&
             $.isFunction(dfd = @queue[0].deferred)
            dfd result
          @done()
      else
        @done()
            
      $.when(result).then @run, if !@opts.stopOnError then @run
