define 'Coffixi/utils/Signal', [
  'Coffixi/utils/SignalBinding'
], (
  SignalBinding
) ->
  
  # Adapted from https://raw.github.com/millermedeiros/js-signals/

  #global SignalBinding:false

  # Signal --------------------------------------------------------
  #================================================================
  validateListener = (listener, fnName) ->
    throw new Error("listener is a required param of {fn}() and should be a Function.".replace("{fn}", fnName))  if typeof listener isnt "function"

  ###*
  Custom event broadcaster
  <br />- inspired by Robert Penner's AS3 Signals.
  @name Signal
  @author Miller Medeiros
  @constructor
  ###
  class Signal
    constructor: (@name) ->
      ###*
      @type Array.<SignalBinding>
      @private
      ###
      @_bindings = []
      @_prevParams = null
      
      # enforce dispatch to aways work on same context (#47)
      @dispatch = =>
        Signal::dispatch.apply @, arguments

    ###*
    If Signal should keep record of previously dispatched parameters and
    automatically execute listener during `add()`/`addOnce()` if Signal was
    already dispatched before.
    @type boolean
    ###
    memorize: false
    
    ###*
    @type boolean
    @private
    ###
    _shouldPropagate: true
    
    ###*
    If Signal is active and should broadcast events.
    <p><strong>IMPORTANT:</strong> Setting this property during a dispatch will only affect the next dispatch, if you want to stop the propagation of a signal use `halt()` instead.</p>
    @type boolean
    ###
    active: true
    
    ###*
    @param {Function} listener
    @param {boolean} isOnce
    @param {Object} [listenerContext]
    @param {Number} [priority]
    @return {SignalBinding}
    @private
    ###
    _registerListener: (listener, isOnce, listenerContext, priority) ->
      prevIndex = @_indexOfListener(listener, listenerContext)
      binding = undefined
      if prevIndex isnt -1
        binding = @_bindings[prevIndex]
        throw new Error("You cannot add" + ((if isOnce then "" else "Once")) + "() then add" + ((if not isOnce then "" else "Once")) + "() the same listener without removing the relationship first.")  if binding.isOnce() isnt isOnce
      else
        binding = new SignalBinding(this, listener, isOnce, listenerContext, priority)
        @_addBinding binding
      binding.execute @_prevParams  if @memorize and @_prevParams
      binding

    
    ###*
    @param {SignalBinding} binding
    @private
    ###
    _addBinding: (binding) ->
      
      #simplified insertion sort
      n = @_bindings.length
      loop
        --n
        break unless @_bindings[n] and binding._priority <= @_bindings[n]._priority
      @_bindings.splice n + 1, 0, binding

    
    ###*
    @param {Function} listener
    @return {number}
    @private
    ###
    _indexOfListener: (listener, context) ->
      n = @_bindings.length
      cur = undefined
      while n--
        cur = @_bindings[n]
        return n  if cur._listener is listener and cur.context is context
      -1

    
    ###*
    Check if listener was attached to Signal.
    @param {Function} listener
    @param {Object} [context]
    @return {boolean} if Signal has the specified listener.
    ###
    has: (listener, context) ->
      @_indexOfListener(listener, context) isnt -1

    
    ###*
    Add a listener to the signal.
    @param {Function} listener Signal handler function.
    @param {Object} [listenerContext] Context on which listener will be executed (object that should represent the `this` variable inside listener function).
    @param {Number} [priority] The priority level of the event listener. Listeners with higher priority will be executed before listeners with lower priority. Listeners with same priority level will be executed at the same order as they were added. (default = 0)
    @return {SignalBinding} An Object representing the binding between the Signal and listener.
    ###
    add: (listener, listenerContext, priority) ->
      validateListener listener, "add"
      @_registerListener listener, false, listenerContext, priority

    
    ###*
    Add listener to the signal that should be removed after first execution (will be executed only once).
    @param {Function} listener Signal handler function.
    @param {Object} [listenerContext] Context on which listener will be executed (object that should represent the `this` variable inside listener function).
    @param {Number} [priority] The priority level of the event listener. Listeners with higher priority will be executed before listeners with lower priority. Listeners with same priority level will be executed at the same order as they were added. (default = 0)
    @return {SignalBinding} An Object representing the binding between the Signal and listener.
    ###
    addOnce: (listener, listenerContext, priority) ->
      validateListener listener, "addOnce"
      @_registerListener listener, true, listenerContext, priority

    
    ###*
    Remove a single listener from the dispatch queue.
    @param {Function} listener Handler function that should be removed.
    @param {Object} [context] Execution context (since you can add the same handler multiple times if executing in a different context).
    @return {Function} Listener handler function.
    ###
    remove: (listener, context) ->
      validateListener listener, "remove"
      i = @_indexOfListener(listener, context)
      if i isnt -1
        @_bindings[i]._destroy() #no reason to a SignalBinding exist if it isn't attached to a signal
        @_bindings.splice i, 1
      listener

    
    ###*
    Remove all listeners from the Signal.
    ###
    removeAll: ->
      n = @_bindings.length
      @_bindings[n]._destroy()  while n--
      @_bindings.length = 0

    
    ###*
    @return {number} Number of listeners attached to the Signal.
    ###
    getNumListeners: ->
      @_bindings.length

    
    ###*
    Stop propagation of the event, blocking the dispatch to next listeners on the queue.
    <p><strong>IMPORTANT:</strong> should be called only during signal dispatch, calling it before/after dispatch won't affect signal broadcast.</p>
    @see Signal.prototype.disable
    ###
    halt: ->
      @_shouldPropagate = false

    
    ###*
    Dispatch/Broadcast Signal to all listeners added to the queue.
    @param {...*} [params] Parameters that should be passed to each handler.
    ###
    dispatch: (params...) ->
      return  unless @active
      n = @_bindings.length
      bindings = undefined
      @_prevParams = params  if @memorize
      
      #should come after memorize
      return  unless n
      bindings = @_bindings.slice() #clone array in case add/remove items during dispatch
      @_shouldPropagate = true #in case `halt` was called before dispatch or during the previous dispatch.
      
      #execute all callbacks until end of the list or until a callback returns `false` or stops propagation
      #reverse loop since listeners with higher priority will be added at the end of the list
      loop
        n--
        break unless bindings[n] and @_shouldPropagate and bindings[n].execute(params) isnt false

    
    ###*
    Forget memorized arguments.
    @see Signal.memorize
    ###
    forget: ->
      @_prevParams = null

    
    ###*
    Remove all bindings from signal and destroy any reference to external objects (destroy Signal object).
    <p><strong>IMPORTANT:</strong> calling any method on the signal instance after calling dispose will throw errors.</p>
    ###
    dispose: ->
      @removeAll()
      delete @_bindings
      delete @_prevParams

    
    ###*
    @return {string} String representation of the object.
    ###
    toString: ->
      "[Signal active:" + @active + " numListeners:" + @getNumListeners() + "]"

  return Signal