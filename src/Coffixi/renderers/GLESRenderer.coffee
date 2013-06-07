###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/renderers/GLESRenderer', [
  './GLESShaders'
  '../utils/Matrix'
  '../Sprite'
  '../textures/BaseTexture'
], (
  GLESShaders
  Matrix
  Sprite
  BaseTexture
) ->

  if Float32Array?
    __Float32Array = Float32Array
  else
    __Float32Array = Array

  if Uint16Array?
    __Uint16Array = Uint16Array
  else
    __Uint16Array = Array
  
  Batch = undefined

  ###
  @class GLESRenderer
  the GLESRenderer is draws the stage and all its content onto a GLES enabled canvas. This renderer should be used for browsers support GLES. This Render works by automatically managing GLESBatchs.
  @constructor
  @param width {Number} the width of the app's view
  @default 0
  @param height {Number} the height of the app's view
  @default 0
  @param transparent {Boolean} the transparency of the render view, default false
  @param filterMode {uint} BaseTexture.
  @default false
  ###
  class GLESRenderer
    @Float32Array: __Float32Array
    @Uint16Array: __Uint16Array
    
    @setBatchClass: (BatchClass) ->
      Batch = BatchClass
    constructor: (@gl, width, height, scale, transparent, @textureFilter=BaseTexture.filterModes.LINEAR, @resizeFilter=BaseTexture.filterModes.LINEAR) ->
      @transparent = !!transparent
      @width = width or 800
      @height = height or 600
      @scale = scale or 1

      @batchs = []

      @initShaders()
      if (@resizeFilter == BaseTexture.filterModes.NEAREST) or scale != 1
        @initFB()

      gl = @gl
      @batch = new Batch(gl)
      gl.disable gl.DEPTH_TEST
      gl.enable gl.BLEND
      gl.colorMask true, true, true, @transparent

      @projectionMatrix = Matrix.mat4.create()

      @contextLost = false

      @resize @width, @height, @scale

    ###
    @private
    ###
    getGLFilterMode: (filterMode) ->
      switch filterMode
        when BaseTexture.filterModes.NEAREST
          glFilterMode = @gl.NEAREST
        when BaseTexture.filterModes.LINEAR
          glFilterMode = @gl.LINEAR
        else
          console.warn 'Unexpected value for filterMode: ' + filterMode + '. Defaulting to LINEAR'
          glFilterMode = @gl.LINEAR
      return glFilterMode

    ###
    @private
    ###
    initShaders: ->
      gl = @gl
      fragmentShader = GLESShaders.CompileShader(gl, GLESShaders.shaderFragmentSrc, gl.FRAGMENT_SHADER)
      vertexShader = GLESShaders.CompileShader(gl, GLESShaders.shaderVertexSrc, gl.VERTEX_SHADER)
      shaderProgram = @shaderProgram = {}
      shaderProgram.handle = gl.createProgram()
      gl.attachShader shaderProgram.handle, vertexShader
      gl.attachShader shaderProgram.handle, fragmentShader
      gl.linkProgram shaderProgram.handle
      if not gl.getProgramParameter(shaderProgram.handle, gl.LINK_STATUS)
        # LOU TODO -- a more elegant failure.
        alert "Could not initialise shaders"
      gl.useProgram shaderProgram.handle
      shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram.handle, "aVertexPosition")
      gl.enableVertexAttribArray shaderProgram.vertexPositionAttribute
      shaderProgram.textureCoordAttribute = gl.getAttribLocation(shaderProgram.handle, "aTextureCoord")
      gl.enableVertexAttribArray shaderProgram.textureCoordAttribute
      shaderProgram.colorAttribute = gl.getAttribLocation(shaderProgram.handle, "aColor")
      gl.enableVertexAttribArray shaderProgram.colorAttribute
      @mvMatrixUniform = gl.getUniformLocation(shaderProgram.handle, "uMVMatrix")
      @samplerUniform = gl.getUniformLocation(shaderProgram.handle, "uSampler")

      # LOU TODO -- pass shader program to Batch properly (that's the only thing that uses this)
      GLESShaders.shaderProgram = shaderProgram

      screenFragmentShader = GLESShaders.CompileShader(gl, GLESShaders.screenShaderFragmentSrc, gl.FRAGMENT_SHADER)
      screenVertexShader = GLESShaders.CompileShader(gl, GLESShaders.screenShaderVertexSrc, gl.VERTEX_SHADER)
      @screenProgram = {}
      screenProgram = @screenProgram
      screenProgram.handle = gl.createProgram()
      gl.attachShader screenProgram.handle, screenVertexShader
      gl.attachShader screenProgram.handle, screenFragmentShader
      gl.linkProgram screenProgram.handle
      if not gl.getProgramParameter(screenProgram.handle, gl.LINK_STATUS)
        # LOU TODO -- a more elegant failure.
        alert "Could not initialise shaders"
      gl.useProgram screenProgram.handle
      screenProgram.vertexPositionAttribute = gl.getAttribLocation(screenProgram.handle, "aVertexPosition")
      gl.enableVertexAttribArray screenProgram.vertexPositionAttribute
      screenProgram.textureCoordAttribute = gl.getAttribLocation(screenProgram.handle, "aTextureCoord")
      gl.enableVertexAttribArray screenProgram.textureCoordAttribute
      screenProgram.samplerUniform = gl.getUniformLocation(screenProgram.handle, "uSampler")

    ###
    @private
    ###
    initFB: ->
      gl = @gl
      @rttFramebuffer = {}
      @rttFramebuffer.handle = gl.createFramebuffer()
      gl.bindFramebuffer gl.FRAMEBUFFER, @rttFramebuffer.handle
      fbWidth = 1
      fbHeight = 1
      while (fbWidth < 2048) and (fbWidth < @width)
        fbWidth *= 2
      while (fbHeight < 2048) and (fbHeight < @height)
        fbHeight *= 2
      @rttFramebuffer.width = fbWidth
      @rttFramebuffer.height = fbHeight
      @rttTexture = gl.createTexture()
      gl.bindTexture gl.TEXTURE_2D, @rttTexture
      glFilterMode = @getGLFilterMode @resizeFilter
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, glFilterMode
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, glFilterMode
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
      gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
      gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, @rttFramebuffer.width, @rttFramebuffer.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null
      renderbuffer = gl.createRenderbuffer()

      # TODO: Do we need depth stuff? Probably not.
      gl.bindRenderbuffer gl.RENDERBUFFER, renderbuffer
      gl.renderbufferStorage gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, @rttFramebuffer.width, @rttFramebuffer.height

      gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, @rttTexture, 0
      gl.framebufferRenderbuffer gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderbuffer
      gl.bindTexture gl.TEXTURE_2D, null
      gl.bindRenderbuffer gl.RENDERBUFFER, null
      gl.bindFramebuffer gl.FRAMEBUFFER, null

      @screenCoordBufferHandle = gl.createBuffer()

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

      return


    ###
    Renders the stage to its GLES view
    @method render
    @param stage {Stage} the Stage element to be rendered
    ###
    __render: (stage) ->
      return  if @contextLost

      # clear objects left behind by the previous stage
      if not @__stage?
        @__stage = stage
      else if @__stage isnt stage
        @checkVisibility @__stage, false
        @__stage = stage

      # update children if need be
      # best to remove first!
      i = 0
      while i < stage.__childrenRemoved.length
        @removeDisplayObject stage.__childrenRemoved[i]
        i++
      
      # LOU TODO: Should this be specific to WebGLRenderer?
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
      gl.useProgram @shaderProgram.handle

      gl.clear gl.COLOR_BUFFER_BIT
      gl.clearColor stage.backgroundColorSplit[0], stage.backgroundColorSplit[1], stage.backgroundColorSplit[2], 0

      # set the correct blend mode!
      gl.blendFunc gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA
      gl.uniformMatrix4fv @mvMatrixUniform, false, @projectionMatrix
      
      # render all the batchs!
      renderable = undefined
      i = 0

      while i < @batchs.length
        renderable = @batchs[i]
        if renderable instanceof Batch
          @batchs[i].render()
        ++i
      
      return

    ###
    @private
    ###
    addDisplayObject: (displayObject) ->
      return  unless displayObject.stage # means it was removed
      return  if displayObject.__inGLES #means it is already in GLES
      
      #displayObject.cacheVisible = displayObject.visible;
      
      # TODO if objects parent is not visible then dont add to stage!!!!
      #if(!displayObject.visible)return;
      displayObject.batch = null
      
      #displayObject.cacheVisible = true;
      return  unless displayObject.renderable
      
      # while looping below THE OBJECT MAY NOT HAVE BEEN ADDED
      displayObject.__inGLES = true
      
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
          until previousSprite.children.length is 0
            previousSprite = previousSprite.children[previousSprite.children.length - 1]
        break  if previousSprite is displayObject.stage
        break  unless not previousSprite.renderable or not previousSprite.__inGLES
      
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
        break  unless not nextSprite.renderable or not nextSprite.__inGLES
      
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
          if not (nextSprite instanceof Sprite)
            # TODO re-word!
            nextBatch = nextSprite
          else
            nextBatch = nextSprite.batch
            
            #batch may not exist if item was added to the display list but not to the GLES
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
                  #              * OOPS!
                  #              * seems the new sprite is in the middle of a batch
                  #              * lets split it.. 
                  #              
                  batch = Batch._getBatch(@gl)
                  index = @batchs.indexOf(previousBatch)
                  batch.init displayObject
                  @batchs.splice index + 1, 0, batch, splitBatch
                  return
        #
        #    * looks like it does not belong to any batch!
        #    * but is also not intersecting one..
        #    * time to create anew one!
        #    
        batch = Batch._getBatch(@gl)
        batch.init displayObject
        if previousBatch
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
      displayObject.__inGLES = false
      
      #
      #  * removing is a lot quicker..
      #  * 
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
      #  * Looks like there is somthing that needs removing!
      #  
      if batchToRemove
        index = @batchs.indexOf(batchToRemove)
        return  if index is -1 # this means it was added then removed before rendered
        
        # ok so.. check to see if you adjacent batchs should be joined.
        # TODO may optimise?
        if index is 0 or index is @batchs.length - 1
          
          # wha - eva! just get of the empty batch!
          @batchs.splice index, 1
          Batch._returnBatch batchToRemove  if batchToRemove instanceof Batch
          return
        if @batchs[index - 1] instanceof Batch and @batchs[index + 1] instanceof Batch
          if @batchs[index - 1].texture is @batchs[index + 1].texture and @batchs[index - 1].blendMode is @batchs[index + 1].blendMode
            
            #console.log("MERGE")
            @batchs[index - 1].merge @batchs[index + 1]
            Batch._returnBatch batchToRemove  if batchToRemove instanceof Batch
            Batch._returnBatch @batchs[index + 1]
            @batchs.splice index, 2
            return
        @batchs.splice index, 1
        Batch._returnBatch batchToRemove  if batchToRemove instanceof Batch

    ###
    resizes the GLES view to the specified width and height
    @method resize
    @param width {Number} the new width of the GLES view
    @param height {Number} the new height of the GLES view
    @param scale {Number} the size of one game-pixel in device-pixels
    ###
    resize: (width, height, scale) ->
      @width = Math.round width
      @height = Math.round height
      @scale = scale
      gl = @gl
      @offsetX = (@getContainerWidth() - (@width*scale)) / 2
      @offsetY = (@getContainerHeight() - (@height*scale)) / 2
      gl.viewport @offsetX, @offsetY, @width*scale, @height*scale
      projectionMatrix = @projectionMatrix
      projectionMatrix[0] = 2 / @width
      projectionMatrix[5] = -2 / @height
      projectionMatrix[12] = -1
      projectionMatrix[13] = 1

      if (@resizeFilter != BaseTexture.filterModes.NEAREST) or scale == 1
        gl.enable gl.BLEND
        @render = @__render
      else
        @initFB()

        widthCoord = @width / @rttFramebuffer.width
        heightCoord = @height / @rttFramebuffer.height

        buf = new GLESRenderer.Float32Array 24
        buf[ 0] = -1
        buf[ 1] = -1
        buf[ 2] = 0
        buf[ 3] = 0
        buf[ 4] = 1
        buf[ 5] = -1
        buf[ 6] = widthCoord
        buf[ 7] = 0
        buf[ 8] = -1
        buf[ 9] = 1
        buf[10] = 0
        buf[11] = heightCoord
        buf[12] = -1
        buf[13] = 1
        buf[14] = 0
        buf[15] = heightCoord
        buf[16] = 1
        buf[17] = -1
        buf[18] = widthCoord
        buf[19] = 0
        buf[20] = 1
        buf[21] = 1
        buf[22] = widthCoord
        buf[23] = heightCoord
        @screenCoordBuffer = buf

        screenProgram = @screenProgram
        gl.useProgram screenProgram.handle
        
        gl.bindBuffer gl.ARRAY_BUFFER, @screenCoordBufferHandle
        gl.bufferData gl.ARRAY_BUFFER, @screenCoordBuffer, gl.STATIC_DRAW

        @render = (stage) =>
          return  if @contextLost

          gl.bindFramebuffer gl.FRAMEBUFFER, @rttFramebuffer.handle
          gl.viewport 0,0, @width, @height

          gl.enable gl.BLEND
          @__render(stage)
          gl.useProgram screenProgram.handle

          gl.bindFramebuffer gl.FRAMEBUFFER, null
          gl.viewport @offsetX, @offsetY, @width*scale, @height*scale

          gl.activeTexture gl.TEXTURE0
          gl.bindTexture gl.TEXTURE_2D, @rttTexture

          gl.bindBuffer gl.ARRAY_BUFFER, @screenCoordBufferHandle
          gl.enableVertexAttribArray screenProgram.vertexPositionAttribute
          gl.vertexAttribPointer screenProgram.vertexPositionAttribute, 2, gl.FLOAT, false, 16, 0

          gl.enableVertexAttribArray screenProgram.textureCoordAttribute
          gl.vertexAttribPointer screenProgram.textureCoordAttribute, 2, gl.FLOAT, false, 16, 8

          gl.disable gl.BLEND
          gl.drawArrays gl.TRIANGLES, 0, @screenCoordBuffer.length / 4
    
    getView: -> @view

  return GLESRenderer