define 'Coffixi/utils/HasSignals', [
  'combo/cg'
  'Coffixi/utils/Signal'
], (
  cg
  Signal
)->

  wrapListener = (listener) ->
    return ->
      listener.call @, arguments...  unless @paused

  # LOU TODO: Docs
  __signal: (name, create=false) ->
    if not create
      signal = @__signals?[name]
    else
      @__signals ?= {}
      @__signals[name] ?= new Signal
      signal = @__signals[name]
    
    return signal

  __on: (signaler, name, listener, funcName) ->
    if typeof signaler is 'string' # on('eventName', listener)
      listener = name
      name = signaler
      signaler = @
      _listener = wrapListener(listener)
    else # on(signaler, 'eventName', listener)
      _listener = wrapListener(listener)
      # There's a definite risk for a memory leak here; if the signaler gets 
      #  disposed there's still a reference to it here.
      # One wacky solution: use the 'destroy' signal
      signaler.once '__destroy__', -> @__listeners.splice(@__listeners.indexOf(listenerData),1)

    @__listeners ?= []
    listenerData = [signaler, name, _listener, listener]
    @__listeners.push listenerData

    signaler.__signal(name, true)[funcName] _listener, @

  on: (signaler, name, listener) ->
    @__on(signaler, name, listener, 'add')
    return @

  once: (signaler, name, listener) ->
    @__on(signaler, name, listener, 'addOnce')
    return @

  off: (args...) ->
    if args.length is 1
      # Remove all signal listeners with this object as context of a specific name:
      # eg. @off 'click'
      signaler = @
      name = args[0]
    else if args.length is 2
      if typeof args[0] is 'string'
        # Remove all signal listeners with this object as context of a specific name:
        # eg. @off 'click', specificClickListener
        signaler = @
        name = args[0]
        listener = args[1]
      else
        # Remove all signal listeners with this object as context of a specific name:
        # eg. @off signaler, 'click'
        signaler = args[0]
        name = args[1]
    else
      signaler = args[0]
      name = args[1]
      listener = args[2]

    signal = signaler.__signal name
    return  if not signal?

    if listener?
      for [_s, _n, wrapped, _l] in @__listeners when (_s is signaler) and (_n is name) and (_l is listener)
        signal.remove wrapped, @
    else
      for [_s, _n, _l] in @__listeners when (_s is signaler) and (_n is name)
        signal.remove _l, @

    return @

  halt: (name) ->
    @__signal(name)?.halt()
    return @

  emit: (name, args...) ->
    @__signal(name)?.dispatch args...
    return @

  _disposeListeners: ->
    for [signaler, name, listener] in @__listeners
      @off signaler, name, listener
    return