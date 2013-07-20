###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/renderers/webgl/GLESRenderer', [
  'Coffixi/utils/Utils'
  'Coffixi/utils/Module'
  'Coffixi/core/Matrix'
  'Coffixi/display/Sprite'
  'Coffixi/extras/TilingSprite'
  'Coffixi/extras/Strip'
  'Coffixi/primitives/Graphics'
  'Coffixi/textures/BaseTexture'
  'Coffixi/textures/Texture'
  'Coffixi/core/Rectangle'
  'Coffixi/core/Point'
  'Coffixi/renderers/webgl/GLESShaders'
  'Coffixi/renderers/webgl/GLESGraphics'
], (
  Utils
  Module
  Matrix
  Sprite
  TilingSprite
  Strip
  Graphics
  BaseTexture
  Texture
  Rectangle
  Point
  GLESShaders
  GLESGraphics
) ->

  Batch = undefined
  
  ###
  A GLESRenderGroup Enables a group of sprites to be drawn using the same settings.
  if a group of sprites all have the same baseTexture and blendMode then they can be
  grouped into a batch. All the sprites in a batch can then be drawn in one go by the
  GPU which is hugely efficient. ALL sprites in the GLES renderer are added to a batch
  even if the batch only contains one sprite. Batching is handled automatically by the
  GLES renderer. A good tip is: the smaller the number of batchs there are, the faster
  the GLES renderer will run.

  @class GLESRenderGroup
  @contructor
  @param gl {GLESContext} An instance of the GLES context
  ###
  class GLESRenderGroup
    constructor: (gl, @textureFilter=BaseTexture.filterModes.LINEAR) ->
      @gl = gl
      @root
      @backgroundColor
      @batchs = []
      @toRemove = []

    ###
    Add a display object to the webgl renderer

    @method setRenderable
    @param displayObject {DisplayObject}
    @private
    ###
    setRenderable: (displayObject) ->
      
      # has this changed??
      @removeDisplayObjectAndChildren @root  if @root
      displayObject.worldVisible = displayObject.visible
      
      # soooooo //
      # to check if any batchs exist already??
      
      # TODO what if its already has an object? should remove it
      @root = displayObject
      @addDisplayObjectAndChildren displayObject


    ###
    Renders the stage to its webgl view

    @method render
    @param projection {Object}
    ###
    render: (projection) ->
      GLESRenderer.updateTextures @textureFilter
      gl = @gl
      gl.uniform2f GLESShaders.shaderProgram.projectionVector, projection.x, projection.y
      gl.blendFunc gl.ONE, gl.ONE_MINUS_SRC_ALPHA
      
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
          @renderTilingSprite renderable, projection  if renderable.visible
        else if renderable instanceof Strip
          @renderStrip renderable, projection  if renderable.visible
        else if renderable instanceof Graphics
          GLESGraphics.renderGraphics renderable, projection  if renderable.visible and renderable.renderable #, projectionMatrix);
        else if renderable instanceof FilterBlock
          
          #
          #      * for now only masks are supported..
          #      
          if renderable.open
            gl.enable gl.STENCIL_TEST
            gl.colorMask false, false, false, false
            gl.stencilFunc gl.ALWAYS, 1, 0xff
            gl.stencilOp gl.KEEP, gl.KEEP, gl.REPLACE
            GLESGraphics.renderGraphics renderable.mask, projection
            gl.colorMask true, true, true, false
            gl.stencilFunc gl.NOTEQUAL, 0, 0xff
            gl.stencilOp gl.KEEP, gl.KEEP, gl.KEEP
          else
            gl.disable gl.STENCIL_TEST
        i++

    ###
    Renders the stage to its webgl view

    @method handleFilter
    @param filter {FilterBlock}
    @private
    ###
    handleFilter: (filter, projection) ->

    ###
    Renders a specific displayObject

    @method renderSpecific
    @param displayObject {DisplayObject}
    @param projection {Object}
    @private
    ###
    renderSpecific: (displayObject, projection) ->
      GLESRenderer.updateTextures @textureFilter
      gl = @gl
      @checkVisibility displayObject, displayObject.visible
      
      # gl.uniformMatrix4fv(GLESShaders.shaderProgram.mvMatrixUniform, false, projectionMatrix);
      gl.uniform2f GLESShaders.shaderProgram.projectionVector, projection.x, projection.y
      
      # to do!
      # render part of the scene...
      startIndex = undefined
      startBatchIndex = undefined
      endIndex = undefined
      endBatchIndex = undefined
      
      #
      #  *  LOOK FOR THE NEXT SPRITE
      #  *  This part looks for the closest next sprite that can go into a batch
      #  *  it keeps looking until it finds a sprite or gets to the end of the display
      #  *  scene graph
      #  
      nextRenderable = displayObject.first
      while nextRenderable._iNext
        nextRenderable = nextRenderable._iNext
        break  if nextRenderable.renderable and nextRenderable.__renderGroup
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
        else
          @renderSpecial startBatch, projection
        return
      
      # now we have first and last!
      startBatchIndex = @batchs.indexOf(startBatch)
      endBatchIndex = @batchs.indexOf(endBatch)
      
      # DO the first batch
      if startBatch instanceof Batch
        startBatch.render startIndex
      else
        @renderSpecial startBatch, projection
      
      # DO the middle batchs..
      i = startBatchIndex + 1

      while i < endBatchIndex
        renderable = @batchs[i]
        if renderable instanceof Batch
          @batchs[i].render()
        else
          @renderSpecial renderable, projection
        i++
      
      # DO the last batch..
      if endBatch instanceof Batch
        endBatch.render 0, endIndex + 1
      else
        @renderSpecial endBatch, projection


    ###
    Renders a specific renderable

    @method renderSpecial
    @param renderable {DisplayObject}
    @param projection {Object}
    @private
    ###
    renderSpecial: (renderable, projection) ->
      if renderable instanceof TilingSprite
        @renderTilingSprite renderable, projection  if renderable.visible
      else if renderable instanceof Strip
        @renderStrip renderable, projection  if renderable.visible
      else if renderable instanceof CustomRenderable
        renderable.renderGLES this, projection  if renderable.visible
      else if renderable instanceof Graphics
        GLESGraphics.renderGraphics renderable, projection  if renderable.visible and renderable.renderable
      else if renderable instanceof FilterBlock
        
        #
        #    * for now only masks are supported..
        #    
        gl = GLESRenderer.gl
        if renderable.open
          gl.enable gl.STENCIL_TEST
          gl.colorMask false, false, false, false
          gl.stencilFunc gl.ALWAYS, 1, 0xff
          gl.stencilOp gl.KEEP, gl.KEEP, gl.REPLACE
          GLESGraphics.renderGraphics renderable.mask, projection
          
          # we know this is a render texture so enable alpha too..
          gl.colorMask true, true, true, true
          gl.stencilFunc gl.NOTEQUAL, 0, 0xff
          gl.stencilOp gl.KEEP, gl.KEEP, gl.KEEP
        else
          gl.disable gl.STENCIL_TEST


    ###
    Checks the visibility of a displayObject

    @method checkVisibility
    @param displayObject {DisplayObject}
    @param globalVisible {Boolean}
    @private
    ###
    checkVisibility: (displayObject, globalVisible) ->
      
      # give the dp a reference to its renderGroup...
      children = displayObject.children
      
      #displayObject.worldVisible = globalVisible;
      i = 0

      while i < children.length
        child = children[i]
        
        # TODO optimize... should'nt need to loop through everything all the time
        child.worldVisible = child.visible and globalVisible
        
        # everything should have a batch!
        # time to see whats new!
        if child.textureChange
          child.textureChange = false
          @updateTexture child  if child.worldVisible
        
        # update texture!!
        @checkVisibility child, child.worldVisible  if child.children.length > 0
        i++


    ###
    Updates a webgl texture

    @method updateTexture
    @param displayObject {DisplayObject}
    @private
    ###
    updateTexture: (displayObject) ->
      
      # TODO definitely can optimse this function..
      @removeObject displayObject
      
      #
      #  *  LOOK FOR THE PREVIOUS RENDERABLE
      #  *  This part looks for the closest previous sprite that can go into a batch
      #  *  It keeps going back until it finds a sprite or the stage
      #  
      previousRenderable = displayObject.first
      until previousRenderable is @root
        previousRenderable = previousRenderable._iPrev
        break  if previousRenderable.renderable and previousRenderable.__renderGroup
      
      #
      #  *  LOOK FOR THE NEXT SPRITE
      #  *  This part looks for the closest next sprite that can go into a batch
      #  *  it keeps looking until it finds a sprite or gets to the end of the display
      #  *  scene graph
      #  
      nextRenderable = displayObject.last
      while nextRenderable._iNext
        nextRenderable = nextRenderable._iNext
        break  if nextRenderable.renderable and nextRenderable.__renderGroup
      @insertObject displayObject, previousRenderable, nextRenderable


    ###
    Adds filter blocks

    @method addFilterBlocks
    @param start {FilterBlock}
    @param end {FilterBlock}
    @private
    ###
    addFilterBlocks: (start, end) ->
      start.__renderGroup = this
      end.__renderGroup = this
      
      #
      #  *  LOOK FOR THE PREVIOUS RENDERABLE
      #  *  This part looks for the closest previous sprite that can go into a batch
      #  *  It keeps going back until it finds a sprite or the stage
      #  
      previousRenderable = start
      until previousRenderable is @root
        previousRenderable = previousRenderable._iPrev
        break  if previousRenderable.renderable and previousRenderable.__renderGroup
      @insertAfter start, previousRenderable
      
      #
      #  *  LOOK FOR THE NEXT SPRITE
      #  *  This part looks for the closest next sprite that can go into a batch
      #  *  it keeps looking until it finds a sprite or gets to the end of the display
      #  *  scene graph
      #  
      previousRenderable2 = end
      until previousRenderable2 is @root
        previousRenderable2 = previousRenderable2._iPrev
        break  if previousRenderable2.renderable and previousRenderable2.__renderGroup
      @insertAfter end, previousRenderable2


    ###
    Remove filter blocks

    @method removeFilterBlocks
    @param start {FilterBlock}
    @param end {FilterBlock}
    @private
    ###
    removeFilterBlocks: (start, end) ->
      @removeObject start
      @removeObject end


    ###
    Adds a display object and children to the webgl context

    @method addDisplayObjectAndChildren
    @param displayObject {DisplayObject}
    @private
    ###
    addDisplayObjectAndChildren: (displayObject) ->
      displayObject.__renderGroup.removeDisplayObjectAndChildren displayObject  if displayObject.__renderGroup
      
      #
      #  *  LOOK FOR THE PREVIOUS RENDERABLE
      #  *  This part looks for the closest previous sprite that can go into a batch
      #  *  It keeps going back until it finds a sprite or the stage
      #  
      previousRenderable = displayObject.first
      until previousRenderable is @root
        previousRenderable = previousRenderable._iPrev
        break  if previousRenderable.renderable and previousRenderable.__renderGroup
      
      #
      #  *  LOOK FOR THE NEXT SPRITE
      #  *  This part looks for the closest next sprite that can go into a batch
      #  *  it keeps looking until it finds a sprite or gets to the end of the display
      #  *  scene graph
      #  
      nextRenderable = displayObject.last
      while nextRenderable._iNext
        nextRenderable = nextRenderable._iNext
        break  if nextRenderable.renderable and nextRenderable.__renderGroup
      
      # one the display object hits this. we can break the loop 
      tempObject = displayObject.first
      testObject = displayObject.last._iNext
      loop
        tempObject.__renderGroup = this
        if tempObject.renderable
          @insertObject tempObject, previousRenderable, nextRenderable
          previousRenderable = tempObject
        tempObject = tempObject._iNext
        break unless tempObject isnt testObject


    ###
    Removes a display object and children to the webgl context

    @method removeDisplayObjectAndChildren
    @param displayObject {DisplayObject}
    @private
    ###
    removeDisplayObjectAndChildren: (displayObject) ->
      return  unless displayObject.__renderGroup is this
      
      # var displayObject = displayObject.first;
      lastObject = displayObject.last
      loop
        displayObject.__renderGroup = null
        @removeObject displayObject  if displayObject.renderable
        displayObject = displayObject._iNext
        break unless displayObject


    ###
    Inserts a displayObject into the linked list

    @method insertObject
    @param displayObject {DisplayObject}
    @param previousObject {DisplayObject}
    @param nextObject {DisplayObject}
    @private
    ###
    insertObject: (displayObject, previousObject, nextObject) ->
      
      # while looping below THE OBJECT MAY NOT HAVE BEEN ADDED
      previousSprite = previousObject
      nextSprite = nextObject
      
      #
      #  * so now we have the next renderable and the previous renderable
      #  * 
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
        return
      else if displayObject instanceof TilingSprite
        
        # add to a batch!!
        @initTilingSprite displayObject
      
      # this.batchs.push(displayObject);
      else if displayObject instanceof Strip
        
        # add to a batch!!
        @initStrip displayObject
      
      # this.batchs.push(displayObject);
      else displayObject # instanceof Graphics)
      
      #displayObject.initWebGL(this);
      
      # add to a batch!!
      #this.initStrip(displayObject);
      #this.batchs.push(displayObject);
      @insertAfter displayObject, previousSprite


    # insert and SPLIT!

    ###
    Inserts a displayObject into the linked list

    @method insertAfter
    @param item {DisplayObject}
    @param displayObject {DisplayObject} The object to insert
    @private
    ###
    insertAfter: (item, displayObject) ->
      if displayObject instanceof Sprite
        previousBatch = displayObject.batch
        if previousBatch
          
          # so this object is in a batch!
          
          # is it not? need to split the batch
          if previousBatch.tail is displayObject
            
            # is it tail? insert in to batchs 
            index = @batchs.indexOf(previousBatch)
            @batchs.splice index + 1, 0, item
          else
            
            # TODO MODIFY ADD / REMOVE CHILD TO ACCOUNT FOR FILTERS (also get prev and next) //
            
            # THERE IS A SPLIT IN THIS BATCH! //
            splitBatch = previousBatch.split(displayObject.__next)
            
            # COOL!
            # add it back into the array  
            #
            #        * OOPS!
            #        * seems the new sprite is in the middle of a batch
            #        * lets split it.. 
            #        
            index = @batchs.indexOf(previousBatch)
            @batchs.splice index + 1, 0, item, splitBatch
        else
          @batchs.push item
      else
        index = @batchs.indexOf(displayObject)
        @batchs.splice index + 1, 0, item


    ###
    Removes a displayObject from the linked list

    @method removeObject
    @param displayObject {DisplayObject} The object to remove
    @private
    ###
    removeObject: (displayObject) ->
      
      # loop through children..
      # display object //
      
      # add a child from the render group..
      # remove it and all its children!
      #displayObject.cacheVisible = false;//displayObject.visible;
      
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


    ###
    Initializes a tiling sprite

    @method initTilingSprite
    @param sprite {TilingSprite} The tiling sprite to initialize
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
    Renders a Strip

    @method renderStrip
    @param strip {Strip} The strip to render
    @param projection {Object}
    @private
    ###
    renderStrip: (strip, projection) ->
      gl = @gl
      shaderProgram = GLESShaders.shaderProgram
      
      # mat
      #var mat4Real = Matrix.mat3.toMat4(strip.worldTransform);
      #Matrix.mat4.transpose(mat4Real);
      #Matrix.mat4.multiply(projectionMatrix, mat4Real, mat4Real )
      gl.useProgram GLESShaders.stripShaderProgram
      m = Matrix.mat3.clone(strip.worldTransform)
      Matrix.mat3.transpose m
      
      # set the matrix transform for the 
      gl.uniformMatrix3fv GLESShaders.stripShaderProgram.translationMatrix, false, m
      gl.uniform2f GLESShaders.stripShaderProgram.projectionVector, projection.x, projection.y
      gl.uniform1f GLESShaders.stripShaderProgram.alpha, strip.worldAlpha
      
      #
      # if(strip.blendMode == Sprite.blendModes.NORMAL)
      # {
      #   gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      # }
      # else
      # {
      #   gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_COLOR);
      # }
      # 
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
      
      #console.log(gl.TRIANGLE_STRIP);
      gl.drawElements gl.TRIANGLE_STRIP, strip.indices.length, gl.UNSIGNED_SHORT, 0
      gl.useProgram GLESShaders.shaderProgram


    ###
    Renders a TilingSprite

    @method renderTilingSprite
    @param sprite {TilingSprite} The tiling sprite to render
    @param projectionMatrix {Object}
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
    Initializes a strip to be rendered

    @method initStrip
    @param strip {Strip} The strip to initialize
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

  ###
  the GLESRenderer is draws the stage and all its content onto a webGL enabled canvas. This renderer
  should be used for browsers support webGL. This Render works by automatically managing webGLBatchs.
  So no need for Sprite Batch's or Sprite Cloud's
  Dont forget to add the view to your DOM or you will not see anything :)

  @class GLESRenderer
  @constructor
  @param width=0 {Number} the width of the canvas view
  @param height=0 {Number} the height of the canvas view
  @param view {Canvas} the canvas to use as a view, optional
  @param transparent=false {Boolean} the transparency of the render view, default false
  ###
  class GLESRenderer
    @GLESRenderGroup: GLESRenderGroup
    @setBatchClass: (BatchClass) ->
      Batch = BatchClass
    constructor: (@gl, width, height, transparent, @textureFilter=BaseTexture.filterModes.LINEAR) ->
      # do a catch.. only 1 webGL renderer..
      GLESGraphics.gl = @gl

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
      GLESRenderer.projection = new Point(400, 300)
      @resize @width, @height
      @contextLost = false
      @stageRenderGroup = new GLESRenderGroup @gl, @textureFilter
    
    initShaders: ->
      GLESShaders.initPrimitiveShader @gl
      GLESShaders.initDefaultShader @gl
      GLESShaders.initDefaultStripShader @gl
      GLESShaders.activateDefaultShader @gl

    ###
    Gets a new Batch from the pool

    @static
    @method getBatch
    @return {Batch}
    @private
    ###
    @getBatch: ->
      if Batch._batchs.length is 0
        new Batch(GLESRenderer.gl)
      else
        Batch._batchs.pop()

    ###
    Puts a batch back into the pool

    @static
    @method returnBatch
    @param batch {Batch} The batch to return
    @private
    ###
    @returnBatch: (batch) ->
      batch.clean()
      Batch._batchs.push batch

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
      #	{
      #		var group = stage.__childrenRemoved[i].__renderGroup
      #		if(group)group.removeDisplayObject(stage.__childrenRemoved[i]);
      #	}
      
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
      #	gl.uniformMatrix4fv(this.shaderProgram.mvMatrixUniform, false, this.projectionMatrix);
      gl.bindFramebuffer gl.FRAMEBUFFER, null
      gl.clearColor stage.backgroundColorSplit[0], stage.backgroundColorSplit[1], stage.backgroundColorSplit[2], not @transparent
      gl.clear gl.COLOR_BUFFER_BIT
      
      # HACK TO TEST
      #GLESRenderer.projectionMatrix = this.projectionMatrix;
      @stageRenderGroup.backgroundColor = stage.backgroundColorSplit
      @stageRenderGroup.render GLESRenderer.projection
      
      # after rendering lets confirm all frames that have been uodated..
      if Texture.frameUpdates.length > 0
        i = 0

        while i < Texture.frameUpdates.length
          Texture.frameUpdates[i].updateFrame = false
          i++
        Texture.frameUpdates = []

    ###
    Updates the textures loaded into this webgl renderer

    @static
    @method updateTextures
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

    ###
    Updates a loaded webgl texture

    @static
    @method updateTexture
    @param texture {Texture} The texture to update
    @private
    ###
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
        if not texture._powerOf2
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE
        else
          console.log 'GL_REPEAT'
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT
          gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT
        gl.bindTexture gl.TEXTURE_2D, null


    ###
    Destroys a loaded webgl texture

    @method destroyTexture
    @param texture {Texture} The texture to update
    @private
    ###
    @destroyTexture: (texture) ->
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
    resize: (width, height, viewportWidth, viewportHeight, viewportX, viewportY) ->
      @width = width
      @height = height
      
      @viewportX = viewportX ? 0
      @viewportY = viewportY ? 0

      @viewportWidth = viewportWidth ? @width
      @viewportHeight = viewportHeight ? @height
      @gl.viewport @viewportX, @viewportY, @viewportWidth, @viewportHeight
      
      GLESRenderer.projection.x = @width / 2
      GLESRenderer.projection.y = @height / 2

  return GLESRenderer