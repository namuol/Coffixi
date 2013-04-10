###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/utils/Detector', [
  '../renderers/WebGLRenderer'
  '../renderers/CanvasRenderer'
], (WebGLRenderer, CanvasRenderer) ->
  Detector = {}
  
  ###
  This helper function will automatically detect which renderer you should be using.
  WebGL is the preferred renderer as it is a lot fastest. If webGL is not supported by the browser then this function will return a canvas renderer
  @method autoDetectRenderer
  @static
  @param width {Number} the width of the renderers view
  @param height {Number} the height of the renderers view
  @param view {Canvas} the canvas to use as a view, optional
  @param transparent {Boolean} the transparency of the render view, default false
  @default false
  ###
  Detector.autoDetectRenderer = (width, height, view, transparent) ->
    width = 800  unless width
    height = 600  unless height
    
    # BORROWED from Mr Doob (mrdoob.com)
    webgl = (->
      try
        return !!window.WebGLRenderingContext and !!document.createElement("canvas").getContext("experimental-webgl")
      catch e
        return false
    )()
    
    # TODO SUPPORT WEBGL
    if webgl
      return new WebGLRenderer(width, height, view, transparent)
    return new CanvasRenderer(width, height, view, transparent)

  return Detector