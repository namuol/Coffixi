define 'Coffixi/utils/Utils', ->
  Utils = {}
  
  Utils.HEXtoRGB = (hex) ->
    [(hex >> 16 & 0xFF) / 255, (hex >> 8 & 0xFF) / 255, (hex & 0xFF) / 255]

  ###
  Provides requestAnimationFrame in a cross browser way.
  ###
  # function FrameRequestCallback 
  # DOMElement Element 

  if window?
    window.requestAnimFrame = (->
      window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback, element) ->
        window.setTimeout callback, 1000 / 60
    )()

  ###
  Provides bind in a cross browser way.
  ###
  if typeof Function::bind is not "function"
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

  return Utils