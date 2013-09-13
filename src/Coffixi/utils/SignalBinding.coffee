define 'Coffixi/utils/SignalBinding', ->

  # Adapted from https://raw.github.com/millermedeiros/js-signals/

  # SignalBinding -------------------------------------------------
  #================================================================

  ###
  Object that represents a binding between a Signal and a listener function.
  <br />- <strong>This is an internal constructor and shouldn't be called by regular users.</strong>
  <br />- inspired by Joa Ebert AS3 SignalBinding and Robert Penner's Slot classes.
  @author Miller Medeiros
  @constructor
  @internal
  @name SignalBinding
  @param {Signal} signal Reference to Signal object that listener is currently bound to.
  @param {Function} listener Handler function bound to the signal.
  @param {boolean} isOnce If binding should be executed just once.
  @param {Object} [listenerContext] Context on which listener will be executed (object that should represent the `this` variable inside listener function).
  @param {Number} [priority] The priority level of the event listener. (default = 0).
  ###
  class SignalBinding
    constructor: (signal, listener, isOnce, listenerContext, priority) ->
      ###
      Handler function bound to the signal.
      @type Function
      @private
      ###
      @_listener = listener
      
      ###
      If binding should be executed just once.
      @type boolean
      @private
      ###
      @_isOnce = isOnce
      
      ###
      Context on which listener will be executed (object that should represent the `this` variable inside listener function).
      @memberOf SignalBinding.prototype
      @name context
      @type Object|undefined|null
      ###
      @context = listenerContext
      
      ###
      Reference to Signal object that listener is currently bound to.
      @type Signal
      @private
      ###
      @_signal = signal
      
      ###
      Listener priority
      @type Number
      @private
      ###
      @_priority = priority or 0

    ###
    If binding is active and should be executed.
    @type boolean
    ###
    active: true
    
    ###
    Default parameters passed to listener during `Signal.dispatch` and `SignalBinding.execute`. (curried parameters)
    @type Array|null
    ###
    params: null
    
    ###
    Call listener passing arbitrary parameters.
    <p>If binding was added using `Signal.addOnce()` it will be automatically removed from signal dispatch queue, this method is used internally for the signal dispatch.</p>
    @param {Array} [paramsArr] Array of parameters that should be passed to the listener
    @return {*} Value returned by the listener.
    ###
    execute: (paramsArr) ->
      handlerReturn = undefined
      params = undefined
      if @active and !!@_listener
        params = (if @params then @params.concat(paramsArr) else paramsArr)
        handlerReturn = @_listener.apply(@context, params)
        @detach()  if @_isOnce
      handlerReturn
    
    ###
    Detach binding from signal.
    - alias to: mySignal.remove(myBinding.getListener());
    @return {Function|null} Handler function bound to the signal or `null` if binding was previously detached.
    ###
    detach: ->
      (if @isBound() then @_signal.remove(@_listener, @context) else null)

    ###
    @return {Boolean} `true` if binding is still bound to the signal and have a listener.
    ###
    isBound: ->
      !!@_signal and !!@_listener
    
    ###
    @return {boolean} If SignalBinding will only be executed once.
    ###
    isOnce: ->
      @_isOnce
    
    ###
    @return {Function} Handler function bound to the signal.
    ###
    getListener: ->
      @_listener
    
    ###
    @return {Signal} Signal that listener is currently bound to.
    ###
    getSignal: ->
      @_signal
    
    ###
    Delete instance properties
    @private
    ###
    _destroy: ->
      delete @_signal
      delete @_listener
      delete @context

    ###
    @return {string} String representation of the object.
    ###
    toString: ->
      "[SignalBinding isOnce:" + @_isOnce + ", isBound:" + @isBound() + ", active:" + @active + "]"

  return SignalBinding