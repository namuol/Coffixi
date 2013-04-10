###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/renderers/WebGLRenderer', [
  './WebGLBatch'
  './WebGLShaders'
  '../utils/Matrix'
  '../Sprite'
  '../textures/BaseTexture'
  '../textures/Texture'
], (WebGLBatch, WebGLShaders, Matrix, Sprite, BaseTexture, Texture) ->
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
  class WebGLRenderer
    constructor: (width, height, view, transparent) ->
      @transparent = !!transparent
      @width = width or 800
      @height = height or 600
      @view = view or document.createElement("canvas")
      @view.width = @width
      @view.height = @height
      
      # deal with losing context..	
      scope = this
      @view.addEventListener "webglcontextlost", ((event) ->
        scope.handleContextLost event
      ), false
      @view.addEventListener "webglcontextrestored", ((event) ->
        scope.handleContextRestored event
      ), false
      @batchs = []
      try
        @gl = @view.getContext("experimental-webgl",
          alpha: @transparent
          antialias: false # SPEED UP??
          premultipliedAlpha: false
        )
      catch e
        throw new Error(" This browser does not support webGL. Try using the canvas renderer" + this)
      @initShaders()
      gl = @gl
      @batch = new WebGLBatch(gl)
      gl.disable gl.DEPTH_TEST
      gl.enable gl.BLEND
      gl.colorMask true, true, true, @transparent
      @projectionMatrix = Matrix.mat4.create()
      @resize @width, @height
      @contextLost = false

    ###
    @private
    ###
    initShaders: ->
      gl = @gl
      fragmentShader = WebGLShaders.CompileFragmentShader(gl, WebGLShaders.shaderFragmentSrc)
      vertexShader = WebGLShaders.CompileVertexShader(gl, WebGLShaders.shaderVertexSrc)
      @shaderProgram = gl.createProgram()
      shaderProgram = @shaderProgram
      gl.attachShader shaderProgram, vertexShader
      gl.attachShader shaderProgram, fragmentShader
      gl.linkProgram shaderProgram
      if not gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)
        # LOU TODO -- a more elegant failure.
        alert "Could not initialise shaders"
      gl.useProgram shaderProgram
      shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition")
      gl.enableVertexAttribArray shaderProgram.vertexPositionAttribute
      shaderProgram.textureCoordAttribute = gl.getAttribLocation(shaderProgram, "aTextureCoord")
      gl.enableVertexAttribArray shaderProgram.textureCoordAttribute
      shaderProgram.colorAttribute = gl.getAttribLocation(shaderProgram, "aColor")
      gl.enableVertexAttribArray shaderProgram.colorAttribute
      shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix")
      shaderProgram.samplerUniform = gl.getUniformLocation(shaderProgram, "uSampler")

      # LOU TODO -- pass shader program to WebGLBatch properly (that's the only thing that uses this)
      WebGLShaders.shaderProgram = @shaderProgram

    ###
    @private
    ###
    checkVisibility: (displayObject, globalVisible) ->
      children = displayObject.children
      i = 0
      while i < children.length
        child = children[i]
        
        # TODO optimize... shouldt need to loop through everything all the time
        actualVisibility = child.visible and globalVisible
        
        # everything should have a batch!
        # time to see whats new!
        if child.textureChange
          child.textureChange = false
          if actualVisibility
            @removeDisplayObject child
            @addDisplayObject child
        
        # update texture!!
        unless child.cacheVisible is actualVisibility
          child.cacheVisible = actualVisibility
          if child.cacheVisible
            @addDisplayObject child
          else
            @removeDisplayObject child
        @checkVisibility child, actualVisibility  if child.children.length > 0
        i++


    ###
    Renders the stage to its webGL view
    @method render
    @param stage {Stage} the Stage element to be rendered
    ###
    render: (stage) ->
      return  if @contextLost
      
      # update children if need be
      # best to remove first!
      i = 0
      while i < stage.__childrenRemoved.length
        @removeDisplayObject stage.__childrenRemoved[i]
        i++
      
      # update any textures	
      i = 0
      while i < BaseTexture.texturesToUpdate.length
        @updateTexture BaseTexture.texturesToUpdate[i]
        i++
      
      # empty out the arrays
      stage.__childrenRemoved = []
      stage.__childrenAdded = []
      BaseTexture.texturesToUpdate = []
      
      # recursivly loop through all items!
      @checkVisibility stage, true
      
      # update the scene graph	
      stage.updateTransform()
      gl = @gl
      gl.clear gl.COLOR_BUFFER_BIT
      gl.clearColor stage.backgroundColorSplit[0], stage.backgroundColorSplit[1], stage.backgroundColorSplit[2], 0
      
      # set the correct blend mode!
      gl.blendFunc gl.ONE, gl.ONE_MINUS_SRC_ALPHA
      gl.uniformMatrix4fv @shaderProgram.mvMatrixUniform, false, @projectionMatrix
      
      # render all the batchs!	
      renderable = undefined
      i = 0

      while i < @batchs.length
        renderable = @batchs[i]
        if renderable instanceof WebGLBatch
          @batchs[i].render()
        ++i
      
      # LOU TODO -- gut/modularize interactive portion
      # interaction
      # run interaction!
      if stage.interactive        
        #need to add some events!
        unless stage._interactiveEventsAdded
          stage._interactiveEventsAdded = true
          stage.interactionManager.setTarget this
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
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
        
        #	gl.generateMipmap(gl.TEXTURE_2D);
        gl.bindTexture gl.TEXTURE_2D, null
      @refreshBatchs = true


    ###
    @private
    ###
    addDisplayObject: (displayObject) ->
      return  unless displayObject.stage # means it was removed
      return  if displayObject.__inWebGL #means it is already in webgL
      
      #displayObject.cacheVisible = displayObject.visible;
      
      # TODO if objects parent is not visible then dont add to stage!!!!
      #if(!displayObject.visible)return;
      displayObject.batch = null
      
      #displayObject.cacheVisible = true;
      return  unless displayObject.renderable
      
      # while looping below THE OBJECT MAY NOT HAVE BEEN ADDED
      displayObject.__inWebGL = true
      
      #
      #	 *  LOOK FOR THE PREVIOUS SPRITE
      #	 *  This part looks for the closest previous sprite that can go into a batch
      #	 *  It keeps going back until it finds a sprite or the stage
      #	 
      previousSprite = displayObject
      loop
        if previousSprite.childIndex is 0
          previousSprite = previousSprite.parent
        else
          previousSprite = previousSprite.parent.children[previousSprite.childIndex - 1]
          
          # what if the bloop has children???
          
          # keep diggin till we get to the last child
          previousSprite = previousSprite.children[previousSprite.children.length - 1]  until previousSprite.children.length is 0
        break  if previousSprite is displayObject.stage
        break unless not previousSprite.renderable or not previousSprite.__inWebGL
      
      #while(!(previousSprite instanceof Sprite))
      
      #
      #	 *  LOOK FOR THE NEXT SPRITE
      #	 *  This part looks for the closest next sprite that can go into a batch
      #	 *  it keeps looking until it finds a sprite or gets to the end of the display
      #	 *  scene graph
      #	 * 
      #	 *  These look a lot scarier than the actually are...
      #	 
      nextSprite = displayObject
      loop
        
        # moving forward!
        # if it has no children.. 
        if nextSprite.children.length is 0
          
          # go along to the parent..
          while nextSprite.childIndex is nextSprite.parent.children.length - 1
            nextSprite = nextSprite.parent
            if nextSprite is displayObject.stage
              nextSprite = null
              break
          nextSprite = nextSprite.parent.children[nextSprite.childIndex + 1]  if nextSprite
        else
          nextSprite = nextSprite.children[0]
        break  unless nextSprite
        break unless not nextSprite.renderable or not nextSprite.__inWebGL
      
      #
      #	 * so now we have the next renderable and the previous renderable
      #	 * 
      #	 
      if displayObject instanceof Sprite
        previousBatch = undefined
        nextBatch = undefined
        if previousSprite instanceof Sprite
          previousBatch = previousSprite.batch
          if previousBatch
            if previousBatch.texture is displayObject.texture.baseTexture and previousBatch.blendMode is displayObject.blendMode
              previousBatch.insertAfter displayObject, previousSprite
              return
        else
          
          # TODO reword!
          previousBatch = previousSprite
        if nextSprite
          if nextSprite instanceof Sprite
            nextBatch = nextSprite.batch
            
            #batch may not exist if item was added to the display list but not to the webGL
            if nextBatch
              if nextBatch.texture is displayObject.texture.baseTexture and nextBatch.blendMode is displayObject.blendMode
                nextBatch.insertBefore displayObject, nextSprite
                return
              else
                if nextBatch is previousBatch
                  
                  # THERE IS A SPLIT IN THIS BATCH! //
                  splitBatch = previousBatch.split(nextSprite)
                  
                  # COOL!
                  # add it back into the array	
                  #
                  #							 * OOPS!
                  #							 * seems the new sprite is in the middle of a batch
                  #							 * lets split it.. 
                  #							 
                  batch = WebGLBatch._getBatch(@gl)
                  index = @batchs.indexOf(previousBatch)
                  batch.init displayObject
                  @batchs.splice index + 1, 0, batch, splitBatch
                  return
          else
            
            # TODO re-word!
            nextBatch = nextSprite
        
        #
        #		 * looks like it does not belong to any batch!
        #		 * but is also not intersecting one..
        #		 * time to create anew one!
        #		 
        batch = WebGLBatch._getBatch(@gl)
        batch.init displayObject
        if previousBatch # if this is invalid it means
          index = @batchs.indexOf(previousBatch)
          @batchs.splice index + 1, 0, batch
        else
          @batchs.push batch
      
      # if its somthing else... then custom codes!
      @batchUpdate = true

    ###
    @private
    ###
    removeDisplayObject: (displayObject) ->
      
      #if(displayObject.stage)return;
      displayObject.cacheVisible = false #displayObject.visible;
      return  unless displayObject.renderable
      displayObject.__inWebGL = false
      
      #
      #	 * removing is a lot quicker..
      #	 * 
      #	 
      batchToRemove = undefined
      if displayObject instanceof Sprite
        
        # should always have a batch!
        batch = displayObject.batch
        return  unless batch # this means the display list has been altered befre rendering
        batch.remove displayObject
        batchToRemove = batch  if batch.size is 0
      else
        batchToRemove = displayObject
      
      #
      #	 * Looks like there is somthing that needs removing!
      #	 
      if batchToRemove
        index = @batchs.indexOf(batchToRemove)
        return  if index is -1 # this means it was added then removed before rendered
        
        # ok so.. check to see if you adjacent batchs should be joined.
        # TODO may optimise?
        if index is 0 or index is @batchs.length - 1
          
          # wha - eva! just get of the empty batch!
          @batchs.splice index, 1
          WebGLBatch._returnBatch batchToRemove  if batchToRemove instanceof WebGLBatch
          return
        if @batchs[index - 1] instanceof WebGLBatch and @batchs[index + 1] instanceof WebGLBatch
          if @batchs[index - 1].texture is @batchs[index + 1].texture and @batchs[index - 1].blendMode is @batchs[index + 1].blendMode
            
            #console.log("MERGE")
            @batchs[index - 1].merge @batchs[index + 1]
            WebGLBatch._returnBatch batchToRemove  if batchToRemove instanceof WebGLBatch
            WebGLBatch._returnBatch @batchs[index + 1]
            @batchs.splice index, 2
            return
        @batchs.splice index, 1
        WebGLBatch._returnBatch batchToRemove  if batchToRemove instanceof WebGLBatch

    ###
    resizes the webGL view to the specified width and height
    @method resize
    @param width {Number} the new width of the webGL view
    @param height {Number} the new height of the webGL view
    ###
    resize: (width, height) ->
      @width = width
      @height = height
      @view.width = width
      @view.height = height
      @gl.viewport 0, 0, @width, @height
      projectionMatrix = @projectionMatrix
      projectionMatrix[0] = 2 / @width
      projectionMatrix[5] = -2 / @height
      projectionMatrix[12] = -1
      projectionMatrix[13] = 1

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