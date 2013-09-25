define 'Coffixi/utils/HasSignals', [
  'combo/cg'
  'Coffixi/utils/Signal'
], (
  cg
  Signal
)->

  wrapListener = (listener) ->
    return -> listener.call @, arguments...  unless @paused

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
    if typeof signaler is 'string'
      listener = name
      name = signaler
      signaler = @
      _listener = wrapListener(listener)
    else
      @__listeners ?= []

      _listener = wrapListener(listener)
      # There's a definite risk for a memory leak here; if the signaler gets 
      #  disposed there's still a reference to it here.
      # One wacky solution: use the 'destroy' signal
      listenerData = [signaler, name, _listener]
      @__listeners.push listenerData
      signaler.once '__destroy__', -> @__listeners.splice(@__listeners.indexOf(listenerData),1)

    signaler.__signal(name, true)[funcName] _listener, @

  on: (signaler, name, listener) ->
    @__on(signaler, name, listener, 'add')

  once: (signaler, name, listener) ->
    @__on(signaler, name, listener, 'addOnce')

  off: (signaler, name, listener) ->
    switch arguments.length
      when 1
        name = signaler
        signaler = @
      when 2
        listener = name
        name = signaler
        signaler = @
      # else we assume 3 args

    signal = signaler.__signal(name)
    
    return  unless signal?

    if listener?
      signal.remove listener, @
    else if signaler.__listeners?
      # TODO: This is obviously not an optimal data structure...
      for [_signaler,_name,_listener] in signaler.__listeners
        if _signaler is signaler and _name is _name
          signal.remove _listener, @
    return

  halt: (name) ->
    @__signal(name)?.halt()

  emit: (name, args...) ->
    @__signal(name)?.dispatch args...

  _disposeListeners: ->
    for [signaler, name, listener] in @__listeners
      @off signaler, name, listener