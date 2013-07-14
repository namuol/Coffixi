define 'Coffixi/utils/Utils', ->
  Utils = {}

  ###
  Converts a hex color number to an [R, G, B] array

  @method HEXtoRGB
  @param hex {Number}
  ###
  Utils.HEXtoRGB = (hex) ->
    [(hex >> 16 & 0xFF) / 255, (hex >> 8 & 0xFF) / 255, (hex & 0xFF) / 255]

  if window?
    ###
    A polyfill for requestAnimationFrame
    MIT license
    http://paulirish.com/2011/requestanimationframe-for-smart-animating/
    http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating

    requestAnimationFrame polyfill by Erik Möller. fixes from Paul Irish and Tino Zijdel

    @method requestAnimationFrame
    ###
    lastTime = 0
    vendors = ["ms", "moz", "webkit", "o"]
    x = 0
    while x < vendors.length and not window.requestAnimationFrame
      window.requestAnimationFrame = window[vendors[x] + "RequestAnimationFrame"]
      window.cancelAnimationFrame = window[vendors[x] + "CancelAnimationFrame"] or window[vendors[x] + "CancelRequestAnimationFrame"]
      ++x

    unless window.requestAnimationFrame
      window.requestAnimationFrame = (callback, element) ->
        currTime = new Date().getTime()
        timeToCall = Math.max(0, 16 - (currTime - lastTime))
        id = window.setTimeout(->
          callback currTime + timeToCall
        , timeToCall)
        lastTime = currTime + timeToCall
        id

    ###
    A polyfill for cancelAnimationFrame

    @method cancelAnimationFrame
    ###
    unless window.cancelAnimationFrame
      window.cancelAnimationFrame = (id) ->
        clearTimeout id
    window.requestAnimFrame = window.requestAnimationFrame

  ###
  A polyfill for Function.prototype.bind

  @method bind
  ###
  unless typeof Function::bind is "function"
    Function::bind = (->
      slice = Array::slice
      (thisArg) ->
        bound = ->
          args = boundArgs.concat(slice.call(arguments))
          target.apply (if this instanceof bound then this else thisArg), args
        target = this
        boundArgs = slice.call(arguments, 1)
        throw new TypeError()  unless typeof target is "function"
        bound:: = (F = (proto) ->
          proto and (F:: = proto)
          new F  unless this instanceof F
        )(target::)
        bound
    )()

  ###
  A wrapper for ajax requests to be handled cross browser

  @class AjaxRequest
  @constructor
  ###
  Utils.AjaxRequest = ->
    activexmodes = ["Msxml2.XMLHTTP", "Microsoft.XMLHTTP"] #activeX versions to check for in IE
    if window.ActiveXObject
      #Test for support for ActiveXObject in IE first (as XMLHttpRequest in IE7 is broken)
      i = 0

      while i < activexmodes.length
        try
          return new ActiveXObject(activexmodes[i])
        i++
    
    #suppress error
    else if window.XMLHttpRequest # if Mozilla, Safari etc
      new XMLHttpRequest()
    else
      false

  #
  # * DEBUGGING ONLY
  # 
  Utils.runList = (item) ->
    console.log ">>>>>>>>>"
    console.log "_"
    safe = 0
    tmp = item.first
    console.log tmp
    while tmp._iNext
      safe++
      
      #		console.log(tmp.childIndex + tmp);
      tmp = tmp._iNext
      console.log tmp #.childIndex);
      #	console.log(tmp);
      if safe > 100
        console.log "BREAK"
        break

  if Float32Array?
    Utils.Float32Array = Float32Array
  else
    Utils.Float32Array = Array

  if Uint16Array?
    Utils.Uint16Array = Uint16Array
  else
    Utils.Uint16Array = Array

  return Utils