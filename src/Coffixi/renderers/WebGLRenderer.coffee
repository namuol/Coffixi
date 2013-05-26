###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/renderers/WebGLRenderer', [
  './GLESRenderer'
  './WebGLBatch'
  '../textures/BaseTexture'
  '../textures/Texture'
], (
  GLESRenderer
  WebGLBatch
  BaseTexture
  Texture
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
  @param filterMode {uint} BaseTexture.
  @default false
  ###
  class WebGLRenderer extends GLESRenderer
    constructor: (width, height, scale, view, transparent, textureFilter=BaseTexture.filterModes.LINEAR, resizeFilter=BaseTexture.filterModes.LINEAR) ->

      @view = view or document.createElement("canvas")

      try
        webGL = @view.getContext("experimental-webgl",
          alpha: @transparent
          antialias: false # SPEED UP??
          premultipliedAlpha: false
        )
      catch e
        throw new Error(" This browser does not support webGL. Try using the canvas renderer" + this)

      # deal with losing context..
      @view.addEventListener "webglcontextlost", ((event) =>
        @handleContextLost event
      ), false
      @view.addEventListener "webglcontextrestored", ((event) =>
        @handleContextRestored event
      ), false

      GLESRenderer.setBatchClass WebGLBatch

      super webGL, width, height, scale, transparent, textureFilter, resizeFilter

    ###
    @private
    ###
    updateTexture: (texture) ->
      gl = @gl

      if not texture._glTexture
        texture._glTexture = gl.createTexture()

      if texture.hasLoaded
        gl.bindTexture gl.TEXTURE_2D, texture._glTexture
        gl.pixelStorei gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, texture.source
        glFilterMode = @getGLFilterMode @textureFilter
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, glFilterMode
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, glFilterMode
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
        
        #	gl.generateMipmap(gl.TEXTURE_2D);
        gl.bindTexture gl.TEXTURE_2D, null
      @refreshBatchs = true
    
    getView: -> @view
    getContainerWidth: -> @view.width
    getContainerHeight: -> @view.height

    resize: (width, height, scale) ->
      @view.width = Math.round width * scale
      @view.height = Math.round height * scale
      super width, height, scale
      
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
      @resize @width, @height, @scale

      i = 0
      while i < Texture.cache.length
        @updateTexture Texture.cache[i]
        i++

      i = 0
      while i < @batchs.length
        @batchs[i].restoreLostContext @gl #
        @batchs[i].dirty = true
        i++
      WebGLBatch._restoreBatchs @gl
      @contextLost = false

  return WebGLRenderer