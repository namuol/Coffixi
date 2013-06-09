###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/renderers/GLESRenderer', [
  '../utils/Utils'
  '../utils/Module'
  '../utils/Matrix'
  '../Sprite'
  '../textures/BaseTexture'
  '../textures/Texture'
  '../Rectangle'
  './GLESShaders'
], (
  Utils
  Module
  Matrix
  Sprite
  BaseTexture
  Texture
  Rectangle
  GLESShaders
) ->
  
  ###
  A Batch Enables a group of sprites to be drawn using the same settings.
  if a group of sprites all have the same baseTexture and blendMode then they can be grouped into a batch. All the sprites in a batch can then be drawn in one go by the GPU which is hugely efficient. ALL sprites in the webGL renderer are added to a batch even if the batch only contains one sprite. Batching is handled automatically by the webGL renderer. A good tip is: the smaller the number of batchs there are, the faster the webGL renderer will run.
  @class Batch
  @param an instance of the webGL context
  @return {Batch} Batch {@link Batch}
  ###
  class GLESRenderGroup extends Module
    constructor: (gl, @textureFilter=BaseTexture.filterModes.LINEAR) ->
      @gl = gl
      @root
      @backgroundColor
      @batchs = []
      @toRemove = []

    setRenderable: (displayObject) ->
      
      # has this changed??
      @removeDisplayObjectAndChildren @root  if @root
      displayObject.worldVisible = displayObject.visible
      
      # soooooo //
      # to check if any batchs exist already??
      
      # TODO what if its already has an object? should remove it
      @root = displayObject
      
      #displayObject.__renderGroup = this;
      @addDisplayObjectAndChildren displayObject


    #displayObject
    render: (projectionMatrix) ->
      GLESRenderer.updateTextures @textureFilter
      gl = @gl
      
      # set the flipped matrix..
      gl.uniformMatrix4fv GLESShaders.shaderProgram.mvMatrixUniform, false, projectionMatrix
      
      # TODO remove this by replacing visible with getter setters.. 
      @checkVisibility @root, @root.visible
      
      # will render all the elements in the group
      renderable = undefined
      i = 0

      while i < @batchs.length
        renderable = @batchs[i]
        if renderable instanceof Batch
          @batchs[i].render()
        else if renderable instanceof TilingSprite
          @renderTilingSprite renderable, projectionMatrix  if renderable.visible
        else @renderStrip renderable, projectionMatrix  if renderable.visible  if renderable instanceof Strip
        i++

    renderSpecific: (displayObject, projectionMatrix) ->
      GLESRenderer.updateTextures @textureFilter
      gl = @gl
      @checkVisibility displayObject, displayObject.visible
      gl.uniformMatrix4fv GLESShaders.shaderProgram.mvMatrixUniform, false, projectionMatrix
      
      #console.log("SPECIFIC");
      # to do!
      # render part of the scene...
      startIndex = undefined
      startBatchIndex = undefined
      endIndex = undefined
      endBatchIndex = undefined
      
      # get NEXT Renderable!
      nextRenderable = (if displayObject.renderable then displayObject else @getNextRenderable(displayObject))
      startBatch = nextRenderable.batch
      if nextRenderable instanceof Sprite
        startBatch = nextRenderable.batch
        head = startBatch.head
        next = head
        
        # ok now we have the batch.. need to find the start index!
        if head is nextRenderable
          startIndex = 0
        else
          startIndex = 1
          until head.__next is nextRenderable
            startIndex++
            head = head.__next
      else
        startBatch = nextRenderable
      
      # Get the LAST renderable object
      lastRenderable = displayObject
      endBatch = undefined
      lastItem = displayObject
      while lastItem.children.length > 0
        lastItem = lastItem.children[lastItem.children.length - 1]
        lastRenderable = lastItem  if lastItem.renderable
      if lastRenderable instanceof Sprite
        endBatch = lastRenderable.batch
        head = endBatch.head
        if head is lastRenderable
          endIndex = 0
        else
          endIndex = 1
          until head.__next is lastRenderable
            endIndex++
            head = head.__next
      else
        endBatch = lastRenderable
      
      # TODO - need to fold this up a bit!
      if startBatch is endBatch
        if startBatch instanceof Batch
          startBatch.render startIndex, endIndex + 1
        else if startBatch instanceof TilingSprite
          @renderTilingSprite startBatch, projectionMatrix  if startBatch.visible
        else if startBatch instanceof Strip
          @renderStrip startBatch, projectionMatrix  if startBatch.visible
        else startBatch.renderWebGL this, projectionMatrix  if startBatch.visible  if startBatch instanceof CustomRenderable
        return
      
      # now we have first and last!
      startBatchIndex = @batchs.indexOf(startBatch)
      endBatchIndex = @batchs.indexOf(endBatch)
      
      # DO the first batch
      if startBatch instanceof Batch
        startBatch.render startIndex
      else if startBatch instanceof TilingSprite
        @renderTilingSprite startBatch, projectionMatrix  if startBatch.visible
      else if startBatch instanceof Strip
        @renderStrip startBatch, projectionMatrix  if startBatch.visible
      else startBatch.renderWebGL this, projectionMatrix  if startBatch.visible  if startBatch instanceof CustomRenderable
      
      # DO the middle batchs..
      i = startBatchIndex + 1

      while i < endBatchIndex
        renderable = @batchs[i]
        if renderable instanceof Batch
          @batchs[i].render()
        else if renderable instanceof TilingSprite
          @renderTilingSprite renderable, projectionMatrix  if renderable.visible
        else if renderable instanceof Strip
          @renderStrip renderable, projectionMatrix  if renderable.visible
        else renderable.renderWebGL this, projectionMatrix  if renderable.visible  if renderable instanceof CustomRenderable
        i++
      
      # DO the last batch..
      if endBatch instanceof Batch
        endBatch.render 0, endIndex + 1
      else if endBatch instanceof TilingSprite
        @renderTilingSprite endBatch  if endBatch.visible
      else if endBatch instanceof Strip
        @renderStrip endBatch  if endBatch.visible
      else endBatch.renderWebGL this, projectionMatrix  if endBatch.visible  if endBatch instanceof CustomRenderable

    checkVisibility: (displayObject, globalVisible) ->
      
      # give the dp a refference to its renderGroup...
      children = displayObject.children
      
      #displayObject.worldVisible = globalVisible;
      i = 0

      while i < children.length
        child = children[i]
        
        # TODO optimize... shouldt need to loop through everything all the time
        child.worldVisible = child.visible and globalVisible
        
        # everything should have a batch!
        # time to see whats new!
        if child.textureChange
          child.textureChange = false
          if child.worldVisible
            @removeDisplayObject child
            @addDisplayObject child
        
        # update texture!!
        @checkVisibility child, child.worldVisible  if child.children.length > 0
        i++

    addDisplayObject: (displayObject) ->
      
      # add a child to the render group..
      displayObject.__renderGroup.removeDisplayObjectAndChildren displayObject  if displayObject.__renderGroup
      
      # DONT htink this is needed?
      # displayObject.batch = null;
      displayObject.__renderGroup = this
      
      #displayObject.cacheVisible = true;
      return  unless displayObject.renderable
      
      # while looping below THE OBJECT MAY NOT HAVE BEEN ADDED
      #displayObject.__inWebGL = true;
      previousSprite = @getPreviousRenderable(displayObject)
      nextSprite = @getNextRenderable(displayObject)
      
      #
      #  * so now we have the next renderable and the previous renderable
      #  * 
      #  
      if displayObject instanceof Sprite
        previousBatch = undefined
        nextBatch = undefined
        
        #console.log( previousSprite)
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
                  #              * OOPS!
                  #              * seems the new sprite is in the middle of a batch
                  #              * lets split it.. 
                  #              
                  batch = GLESRenderer.getBatch()
                  index = @batchs.indexOf(previousBatch)
                  batch.init displayObject
                  @batchs.splice index + 1, 0, batch, splitBatch
                  return
          else
            
            # TODO re-word!
            nextBatch = nextSprite
        
        #
        #    * looks like it does not belong to any batch!
        #    * but is also not intersecting one..
        #    * time to create anew one!
        #    
        batch = GLESRenderer.getBatch()
        batch.init displayObject
        if previousBatch # if this is invalid it means
          index = @batchs.indexOf(previousBatch)
          @batchs.splice index + 1, 0, batch
        else
          @batchs.push batch
      else if displayObject instanceof TilingSprite
        
        # add to a batch!!
        @initTilingSprite displayObject
        @batchs.push displayObject
      else if displayObject instanceof Strip
        
        # add to a batch!!
        @initStrip displayObject
        @batchs.push displayObject
      
      # if its somthing else... then custom codes!
      @batchUpdate = true

    addDisplayObjectAndChildren: (displayObject) ->
      
      # TODO - this can be faster - but not as important right now
      @addDisplayObject displayObject
      children = displayObject.children
      i = 0

      while i < children.length
        @addDisplayObjectAndChildren children[i]
        i++

    removeDisplayObject: (displayObject) ->
      
      # loop through children..
      # display object //
      
      # add a child from the render group..
      # remove it and all its children!
      #displayObject.cacheVisible = false;//displayObject.visible;
      displayObject.__renderGroup = null
      return  unless displayObject.renderable
      
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
          GLESRenderer.returnBatch batchToRemove  if batchToRemove instanceof Batch
          return
        if @batchs[index - 1] instanceof Batch and @batchs[index + 1] instanceof Batch
          if @batchs[index - 1].texture is @batchs[index + 1].texture and @batchs[index - 1].blendMode is @batchs[index + 1].blendMode
            
            #console.log("MERGE")
            @batchs[index - 1].merge @batchs[index + 1]
            GLESRenderer.returnBatch batchToRemove  if batchToRemove instanceof Batch
            GLESRenderer.returnBatch @batchs[index + 1]
            @batchs.splice index, 2
            return
        @batchs.splice index, 1
        GLESRenderer.returnBatch batchToRemove  if batchToRemove instanceof Batch

    removeDisplayObjectAndChildren: (displayObject) ->
      # TODO - this can be faster - but not as important right now
      return  unless displayObject.__renderGroup is this
      @removeDisplayObject displayObject
      children = displayObject.children
      i = 0

      while i < children.length
        @removeDisplayObjectAndChildren children[i]
        i++

    ###
    @private
    ###
    getNextRenderable: (displayObject) ->
      #
      #  *  LOOK FOR THE NEXT SPRITE
      #  *  This part looks for the closest next sprite that can go into a batch
      #  *  it keeps looking until it finds a sprite or gets to the end of the display
      #  *  scene graph
      #  * 
      #  *  These look a lot scarier than the actually are...
      #  
      nextSprite = displayObject
      loop
        
        # moving forward!
        # if it has no children.. 
        if nextSprite.children.length is 0
          
          #maynot have a parent
          return null  unless nextSprite.parent
          
          # go along to the parent..
          while nextSprite.childIndex is nextSprite.parent.children.length - 1
            nextSprite = nextSprite.parent
            
            #console.log(">" + nextSprite);
            #       console.log(">-" + this.root);
            if nextSprite is @root or not nextSprite.parent #displayObject.stage)
              nextSprite = null
              break
          nextSprite = nextSprite.parent.children[nextSprite.childIndex + 1]  if nextSprite
        else
          nextSprite = nextSprite.children[0]
        break  unless nextSprite
        break unless not nextSprite.renderable or not nextSprite.__renderGroup
      nextSprite

    getPreviousRenderable: (displayObject) ->
      #
      #  *  LOOK FOR THE PREVIOUS SPRITE
      #  *  This part looks for the closest previous sprite that can go into a batch
      #  *  It keeps going back until it finds a sprite or the stage
      #  
      previousSprite = displayObject
      loop
        if previousSprite.childIndex is 0
          previousSprite = previousSprite.parent
          return null  unless previousSprite
        else
          previousSprite = previousSprite.parent.children[previousSprite.childIndex - 1]
          
          # what if the bloop has children???
          
          # keep diggin till we get to the last child
          previousSprite = previousSprite.children[previousSprite.children.length - 1]  until previousSprite.children.length is 0
        break  if previousSprite is @root
        break unless not previousSprite.renderable or not previousSprite.__renderGroup
      previousSprite

    ###
    @private
    ###
    initTilingSprite: (sprite) ->
      gl = @gl
      
      # make the texture tilable..
      sprite.verticies = new Utils.Float32Array([0, 0, sprite.width, 0, sprite.width, sprite.height, 0, sprite.height])
      sprite.uvs = new Utils.Float32Array([0, 0, 1, 0, 1, 1, 0, 1])
      sprite.colors = new Utils.Float32Array([1, 1, 1, 1])
      sprite.indices = new Utils.Uint16Array([0, 1, 3, 2]) #, 2]);
      sprite._vertexBuffer = gl.createBuffer()
      sprite._indexBuffer = gl.createBuffer()
      sprite._uvBuffer = gl.createBuffer()
      sprite._colorBuffer = gl.createBuffer()
      gl.bindBuffer gl.ARRAY_BUFFER, sprite._vertexBuffer
      gl.bufferData gl.ARRAY_BUFFER, sprite.verticies, gl.STATIC_DRAW
      gl.bindBuffer gl.ARRAY_BUFFER, sprite._uvBuffer
      gl.bufferData gl.ARRAY_BUFFER, sprite.uvs, gl.DYNAMIC_DRAW
      gl.bindBuffer gl.ARRAY_BUFFER, sprite._colorBuffer
      gl.bufferData gl.ARRAY_BUFFER, sprite.colors, gl.STATIC_DRAW
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, sprite._indexBuffer
      gl.bufferData gl.ELEMENT_ARRAY_BUFFER, sprite.indices, gl.STATIC_DRAW
      
      #    return ( (x > 0) && ((x & (x - 1)) == 0) );
      if sprite.texture.baseTexture._glTexture
        gl.bindTexture gl.TEXTURE_2D, sprite.texture.baseTexture._glTexture
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT
        sprite.texture.baseTexture._powerOf2 = true
      else
        sprite.texture.baseTexture._powerOf2 = true

    ###
    @private
    ###
    renderStrip: (strip, projectionMatrix) ->
      gl = @gl
      shaderProgram = GLESShaders.shaderProgram
      
      # mat
      mat4Real = Matrix.mat3.toMat4(strip.worldTransform)
      Matrix.mat4.transpose mat4Real
      Matrix.mat4.multiply projectionMatrix, mat4Real, mat4Real
      gl.uniformMatrix4fv shaderProgram.mvMatrixUniform, false, mat4Real
      if strip.blendMode is Sprite.blendModes.NORMAL
        gl.blendFunc gl.ONE, gl.ONE_MINUS_SRC_ALPHA
      else
        gl.blendFunc gl.ONE, gl.ONE_MINUS_SRC_COLOR
      unless strip.dirty
        gl.bindBuffer gl.ARRAY_BUFFER, strip._vertexBuffer
        gl.bufferSubData gl.ARRAY_BUFFER, 0, strip.verticies
        gl.vertexAttribPointer shaderProgram.vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0
        
        # update the uvs
        gl.bindBuffer gl.ARRAY_BUFFER, strip._uvBuffer
        gl.vertexAttribPointer shaderProgram.textureCoordAttribute, 2, gl.FLOAT, false, 0, 0
        gl.activeTexture gl.TEXTURE0
        gl.bindTexture gl.TEXTURE_2D, strip.texture.baseTexture._glTexture
        gl.bindBuffer gl.ARRAY_BUFFER, strip._colorBuffer
        gl.vertexAttribPointer shaderProgram.colorAttribute, 1, gl.FLOAT, false, 0, 0
        
        # dont need to upload!
        gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, strip._indexBuffer
      else
        strip.dirty = false
        gl.bindBuffer gl.ARRAY_BUFFER, strip._vertexBuffer
        gl.bufferData gl.ARRAY_BUFFER, strip.verticies, gl.STATIC_DRAW
        gl.vertexAttribPointer shaderProgram.vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0
        
        # update the uvs
        gl.bindBuffer gl.ARRAY_BUFFER, strip._uvBuffer
        gl.bufferData gl.ARRAY_BUFFER, strip.uvs, gl.STATIC_DRAW
        gl.vertexAttribPointer shaderProgram.textureCoordAttribute, 2, gl.FLOAT, false, 0, 0
        gl.activeTexture gl.TEXTURE0
        gl.bindTexture gl.TEXTURE_2D, strip.texture.baseTexture._glTexture
        gl.bindBuffer gl.ARRAY_BUFFER, strip._colorBuffer
        gl.bufferData gl.ARRAY_BUFFER, strip.colors, gl.STATIC_DRAW
        gl.vertexAttribPointer shaderProgram.colorAttribute, 1, gl.FLOAT, false, 0, 0
        
        # dont need to upload!
        gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, strip._indexBuffer
        gl.bufferData gl.ELEMENT_ARRAY_BUFFER, strip.indices, gl.STATIC_DRAW
      
      #console.log(gl.TRIANGLE_STRIP)
      gl.drawElements gl.TRIANGLE_STRIP, strip.indices.length, gl.UNSIGNED_SHORT, 0
      gl.uniformMatrix4fv shaderProgram.mvMatrixUniform, false, projectionMatrix

    ###
    @private
    ###
    renderTilingSprite: (sprite, projectionMatrix) ->
      gl = @gl
      shaderProgram = GLESShaders.shaderProgram
      tilePosition = sprite.tilePosition
      tileScale = sprite.tileScale
      offsetX = tilePosition.x / sprite.texture.baseTexture.width
      offsetY = tilePosition.y / sprite.texture.baseTexture.height
      scaleX = (sprite.width / sprite.texture.baseTexture.width) / tileScale.x
      scaleY = (sprite.height / sprite.texture.baseTexture.height) / tileScale.y
      sprite.uvs[0] = 0 - offsetX
      sprite.uvs[1] = 0 - offsetY
      sprite.uvs[2] = (1 * scaleX) - offsetX
      sprite.uvs[3] = 0 - offsetY
      sprite.uvs[4] = (1 * scaleX) - offsetX
      sprite.uvs[5] = (1 * scaleY) - offsetY
      sprite.uvs[6] = 0 - offsetX
      sprite.uvs[7] = (1 * scaleY) - offsetY
      gl.bindBuffer gl.ARRAY_BUFFER, sprite._uvBuffer
      gl.bufferSubData gl.ARRAY_BUFFER, 0, sprite.uvs
      @renderStrip sprite, projectionMatrix

    ###
    @private
    ###
    initStrip: (strip) ->
      
      # build the strip!
      gl = @gl
      shaderProgram = @shaderProgram
      strip._vertexBuffer = gl.createBuffer()
      strip._indexBuffer = gl.createBuffer()
      strip._uvBuffer = gl.createBuffer()
      strip._colorBuffer = gl.createBuffer()
      gl.bindBuffer gl.ARRAY_BUFFER, strip._vertexBuffer
      gl.bufferData gl.ARRAY_BUFFER, strip.verticies, gl.DYNAMIC_DRAW
      gl.bindBuffer gl.ARRAY_BUFFER, strip._uvBuffer
      gl.bufferData gl.ARRAY_BUFFER, strip.uvs, gl.STATIC_DRAW
      gl.bindBuffer gl.ARRAY_BUFFER, strip._colorBuffer
      gl.bufferData gl.ARRAY_BUFFER, strip.colors, gl.STATIC_DRAW
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, strip._indexBuffer
      gl.bufferData gl.ELEMENT_ARRAY_BUFFER, strip.indices, gl.STATIC_DRAW

  Batch = undefined

  ###
  Draws the stage and all its content with pseudo-openGL ES 2. This Render works by automatically managing Batches. So no need for Sprite Batches or Sprite Clouds
  @class GLESRenderer
  @constructor
  @param width {Number} the width of the canvas view
  @default 0
  @param height {Number} the height of the canvas view
  @default 0
  @param transparent {Boolean} the transparency of the render view, default false
  @default false
  ###
  class GLESRenderer
    @GLESRenderGroup: GLESRenderGroup
    @setBatchClass: (BatchClass) ->
      Batch = BatchClass
    constructor: (@gl, width, height, transparent, @textureFilter=BaseTexture.filterModes.LINEAR, @resizeFilter=BaseTexture.filterModes.LINEAR) ->
      #console.log(transparent)
      @transparent = !!transparent
      @width = width or 800
      @height = height or 600
      
      @initShaders()
      gl = GLESRenderer.gl = @gl
      @batch = new Batch(gl)
      gl.disable gl.DEPTH_TEST
      gl.disable gl.CULL_FACE
      gl.enable gl.BLEND
      gl.colorMask true, true, true, @transparent
      @projectionMatrix = Matrix.mat4.create()
      @resize @width, @height
      @contextLost = false
      @stageRenderGroup = new GLESRenderGroup gl, @textureFilter

    ###
    @private
    ###
    @getBatch: ->
      if Batch._batchs.length is 0
        return new Batch(GLESRenderer.gl)
      else
        return Batch._batchs.pop()

    ###
    @private
    ###
    @returnBatch: (batch) ->
      batch.clean()
      Batch._batchs.push batch

    ###
    @private
    ###
    initShaders: ->
      gl = @gl
      fragmentShader = GLESShaders.CompileFragmentShader(gl, GLESShaders.shaderFragmentSrc)
      vertexShader = GLESShaders.CompileVertexShader(gl, GLESShaders.shaderVertexSrc)
      GLESShaders.shaderProgram = {}
      GLESShaders.shaderProgram.handle = gl.createProgram()
      shaderProgram = GLESShaders.shaderProgram
      gl.attachShader shaderProgram.handle, vertexShader
      gl.attachShader shaderProgram.handle, fragmentShader
      gl.linkProgram shaderProgram.handle

      if not gl.getProgramParameter(shaderProgram.handle, gl.LINK_STATUS)
        alert "Could not initialise shaders"

      gl.useProgram shaderProgram.handle
      shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram.handle, "aVertexPosition")
      gl.enableVertexAttribArray shaderProgram.vertexPositionAttribute
      shaderProgram.textureCoordAttribute = gl.getAttribLocation(shaderProgram.handle, "aTextureCoord")
      gl.enableVertexAttribArray shaderProgram.textureCoordAttribute
      shaderProgram.colorAttribute = gl.getAttribLocation(shaderProgram.handle, "aColor")
      gl.enableVertexAttribArray shaderProgram.colorAttribute
      shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram.handle, "uMVMatrix")
      shaderProgram.samplerUniform = gl.getUniformLocation(shaderProgram.handle, "uSampler")

    ###
    Renders the stage to its webGL view
    @method render
    @param stage {Stage} the Stage element to be rendered
    ###
    render: (stage) ->
      return  if @contextLost
      
      # if rendering a new stage clear the batchs..
      if @__stage isnt stage
        
        # TODO make this work
        # dont think this is needed any more?
        #if(this.__stage)this.checkVisibility(this.__stage, false)
        @__stage = stage
        @stageRenderGroup.setRenderable stage
      
      # TODO not needed now... 
      # update children if need be
      # best to remove first!
      #for (var i=0; i < stage.__childrenRemoved.length; i++)
      # {
      #   var group = stage.__childrenRemoved[i].__renderGroup
      #   if(group)group.removeDisplayObject(stage.__childrenRemoved[i]);
      # }
      
      # update any textures 
      GLESRenderer.updateTextures @textureFilter
      
      # recursivly loop through all items!
      #this.checkVisibility(stage, true);
      
      # update the scene graph  
      stage.updateTransform()
      gl = @gl
      
      # -- Does this need to be set every frame? -- //
      gl.colorMask true, true, true, @transparent
      gl.viewport 0, 0, @width, @height
      
      # set the correct matrix..  
      # gl.uniformMatrix4fv(this.shaderProgram.mvMatrixUniform, false, this.projectionMatrix);
      gl.bindFramebuffer gl.FRAMEBUFFER, null
      gl.clearColor stage.backgroundColorSplit[0], stage.backgroundColorSplit[1], stage.backgroundColorSplit[2], @transparent
      gl.clear gl.COLOR_BUFFER_BIT
      @stageRenderGroup.backgroundColor = stage.backgroundColorSplit
      @stageRenderGroup.render @projectionMatrix
      
      # interaction
      # run interaction!
      if stage.interactive
        
        #need to add some events!
        unless stage._interactiveEventsAdded
          stage._interactiveEventsAdded = true
          stage.interactionManager.setTarget this
      
      # after rendering lets confirm all frames that have been uodated..
      if Texture.frameUpdates.length > 0
        i = 0

        while i < Texture.frameUpdates.length
          Texture.frameUpdates[i].updateFrame = false
          i++
        Texture.frameUpdates = []

    ###
    @private
    ###
    @updateTextures: (textureFilter) ->
      i = 0

      while i < BaseTexture.texturesToUpdate.length
        @updateTexture BaseTexture.texturesToUpdate[i], textureFilter
        i++
      i = 0

      while i < BaseTexture.texturesToDestroy.length
        @destroyTexture BaseTexture.texturesToDestroy[i]
        i++
      BaseTexture.texturesToUpdate = []
      BaseTexture.texturesToDestroy = []

    ###
    @private
    ###
    @getGLFilterMode: (filterMode) ->
      switch filterMode
        when BaseTexture.filterModes.NEAREST
          glFilterMode = @gl.NEAREST
        when BaseTexture.filterModes.LINEAR
          glFilterMode = @gl.LINEAR
        else
          console.warn 'Unexpected value for filterMode: ' + filterMode + '. Defaulting to LINEAR'
          glFilterMode = @gl.LINEAR
      return glFilterMode

    @updateTexture: (texture, defaultFilterMode) ->
      if texture.filterMode?
        filterMode = texture.filterMode
      else
        filterMode = defaultFilterMode

      gl = GLESRenderer.gl
      texture._glTexture = gl.createTexture()  unless texture._glTexture
      if texture.hasLoaded
        gl.bindTexture gl.TEXTURE_2D, texture._glTexture
        gl.pixelStorei gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true
        gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, texture.source
        glFilterMode = @getGLFilterMode filterMode
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, glFilterMode
        gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, glFilterMode
        
        # reguler...
        unless texture._powerOf2
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
        else
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT
        gl.bindTexture gl.TEXTURE_2D, null
    
    destroyTexture: (texture) ->
      gl = @gl
      if texture._glTexture
        texture._glTexture = gl.createTexture()
        gl.deleteTexture gl.TEXTURE_2D, texture._glTexture

    ###
    resizes the webGL view to the specified width and height
    @method resize
    @param width {Number} the new width of the webGL view
    @param height {Number} the new height of the webGL view
    ###
    resize: (width, height) ->
      @width = width
      @height = height
      @gl.viewport 0, 0, @width, @height
      projectionMatrix = @projectionMatrix
      projectionMatrix[0] = 2 / @width
      projectionMatrix[5] = -2 / @height
      projectionMatrix[12] = -1
      projectionMatrix[13] = 1

  return GLESRenderer