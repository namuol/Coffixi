###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/renderers/WebGLRenderer', [
  './GLESRenderer'
  './WebGLBatch'
], (
  GLESRenderer
  WebGLBatch
) ->
  
  ###
  the WebGLRenderer is draws the stage and all its content onto a webGL enabled canvas. This renderer should be used for browsers support webGL. This Render works by automatically managing webGLBatchs. So no need for Sprite Batch's or Sprite Cloud's
  Dont forget to add the view to your DOM or you will not see anything :)
  @class WebGLRenderer
  @constructor
  @param width {Number} the width of the canvas view
  @default 0
  @param height {Number} the height of the canvas view
  @default 0
  @param view {Canvas} the canvas to use as a view, optional
  @param transparent {Boolean} the transparency of the render view, default false
  @default false
  ###
  class WebGLRenderer extends GLESRenderer
    constructor: (width, height, view, transparent, textureFilter=BaseTexture.filterModes.LINEAR) ->
      @view = view or document.createElement("canvas")
      @view.width = @width
      @view.height = @height
      
      # deal with losing context..
      @view.addEventListener "webglcontextlost", ((event) =>
        @handleContextLost event
      ), false
      @view.addEventListener "webglcontextrestored", ((event) =>
        @handleContextRestored event
      ), false
      @batchs = []
      try
        webGL = @view.getContext("experimental-webgl",
          alpha: @transparent
          antialias: false # SPEED UP??
          premultipliedAlpha: true
        )
      catch e
        throw new Error(" This browser does not support webGL. Try using the canvas renderer" + this)

      GLESRenderer.setBatchClass WebGLBatch

      super webGL, width, height, transparent, textureFilter

    ###
    @private
    ###
    handleContextLost: (event) ->
      event.preventDefault()
      @contextLost = true

    ###
    @private
    ###
    handleContextRestored: (event) ->
      @gl = @view.getContext("experimental-webgl",
        alpha: true
      )
      @initShaders()
      i = 0

      while i < Texture.cache.length
        @updateTexture Texture.cache[i], @textureFilter
        i++
      i = 0

      while i < @batchs.length
        @batchs[i].restoreLostContext @gl #
        @batchs[i].dirty = true
        i++
      Batch._restoreBatchs @gl
      @contextLost = false
    resize: (width, height) ->
      @view.width = width
      @view.height = height
      super
        
    getView: -> @view
    getContainerWidth: -> @view.width
    getContainerHeight: -> @view.height