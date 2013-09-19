define 'Coffixi/utils/HasSignals', [
  'combo/cg'
  'Coffixi/utils/Signal'
], (
  cg
  Signal
)->
  # LOU TODO: Docs
  __signal: (name, create=false) ->
    if not create
      signal = @__signals?[name]
    else
      @__signals ?= {}
      @__signals[name] ?= new Signal
      signal = @__signals[name]
    
    signal

  __on: (name, signaler, listener, funcName) ->
    if typeof signaler is 'function'
      listener = signaler
      signaler = @
    else
      @__listeners ?= []
      # There's a definite risk for a memory leak here; if the signaler gets 
      #  disposed there's still a reference to it here.
      # One wacky solution: use a 'dispose' signal 
      listenerData = [signaler, name, listener]
      @__listeners.push listenerData
      signaler.once 'destroy', -> @__listeners.splice(@__listeners.indexOf(listenerData),1)
    signaler.__signal(name, true)[funcName] listener, signaler
  on: (name, signaler, listener) -> @__on(name, signaler, listener, 'add')
  once: (name, signaler, listener) -> @__on(name, signaler, listener, 'addOnce')
  off: (name, listener) ->
    signal = @__signal(name)
    return  unless signal?
    if listener?
      signal.remove listener, @
    else
      signal.removeAll()
  halt: (name) -> @__signal(name)?.halt()
  emit: (name, args...) -> @__signal(name)?.dispatch args...
  _disposeListeners: ->
    for [signaler, name, listener] in @__listeners
      signaler.off name, listener