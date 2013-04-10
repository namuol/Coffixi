###
@author Mat Groves http://matgroves.com/ @Doormat23
###
define 'Coffixi/renderers/WebGLBatch', [
  '../Sprite'
  './WebGLShaders'
], (Sprite, WebGLShaders) ->
  ###
  A WebGLBatch Enables a group of sprites to be drawn using the same settings.
  if a group of sprites all have the same baseTexture and blendMode then they can be grouped into a batch. All the sprites in a batch can then be drawn in one go by the GPU which is hugely efficient. ALL sprites in the webGL renderer are added to a batch even if the batch only contains one sprite. Batching is handled automatically by the webGL renderer. A good tip is: the smaller the number of batchs there are, the faster the webGL renderer will run.
  @class WebGLBatch
  @param an instance of the webGL context
  @return {WebGLBatch} WebGLBatch {@link WebGLBatch}
  ###
  class WebGLBatch
    @_batchs: []

    ###
    @private
    ###
    @_getBatch: (gl) ->
      if @_batchs.length is 0
        new WebGLBatch(gl)
      else
        @_batchs.pop()

    ###
    @private
    ###
    @_returnBatch: (batch) ->
      batch.clean()
      WebGLBatch._batchs.push batch

    ###
    @private
    ###
    @_restoreBatchs: (gl) ->
      i = 0
      while i < WebGLBatch._batchs.length
        WebGLBatch._batchs[i].restoreLostContext gl
        i++

    constructor: (gl) ->
      @gl = gl
      @size = 0
      @vertexBuffer = gl.createBuffer()
      @indexBuffer = gl.createBuffer()
      @uvBuffer = gl.createBuffer()
      @colorBuffer = gl.createBuffer()
      @blendMode = Sprite.blendModes.NORMAL
      @dynamicSize = 1

    ###
    Cleans the batch so that is can be returned to an object pool and reused
    ###
    clean: ->
      @verticies = []
      @uvs = []
      @indices = []
      @colors = []
      
      #this.sprites = [];
      @dynamicSize = 1
      @texture = null
      @last = null
      @size = 0
      @head
      @tail

    #
    # * recreates the buffers in the event of a context loss
    # 
    restoreLostContext: (gl) ->
      @gl = gl
      @vertexBuffer = gl.createBuffer()
      @indexBuffer = gl.createBuffer()
      @uvBuffer = gl.createBuffer()
      @colorBuffer = gl.createBuffer()

    ###
    inits the batch's texture and blend mode based if the supplied sprite
    @method init
    @param sprite {Sprite} the first sprite to be added to the batch. Only sprites with the same base texture and blend mode will be allowed to be added to this batch
    ###
    init: (sprite) ->
      sprite.batch = this
      @dirty = true
      @blendMode = sprite.blendMode
      @texture = sprite.texture.baseTexture
      
      #	this.sprites.push(sprite);
      @head = sprite
      @tail = sprite
      @size = 1
      @growBatch()


    ###
    inserts a sprite before the specified sprite
    @method insertBefore
    @param sprite {Sprite} the sprite to be added
    @param nextSprite {nextSprite} the first sprite will be inserted before this sprite
    ###
    insertBefore: (sprite, nextSprite) ->
      @size++
      sprite.batch = this
      @dirty = true
      tempPrev = nextSprite.__prev
      nextSprite.__prev = sprite
      sprite.__next = nextSprite
      if tempPrev
        sprite.__prev = tempPrev
        tempPrev.__next = sprite
      else
        @head = sprite


    #this.head.__prev = null

    ###
    inserts a sprite after the specified sprite
    @method insertAfter
    @param sprite {Sprite} the sprite to be added
    @param  previousSprite {Sprite} the first sprite will be inserted after this sprite
    ###
    insertAfter: (sprite, previousSprite) ->
      @size++
      sprite.batch = this
      @dirty = true
      tempNext = previousSprite.__next
      previousSprite.__next = sprite
      sprite.__prev = previousSprite
      if tempNext
        sprite.__next = tempNext
        tempNext.__prev = sprite
      else
        @tail = sprite


    ###
    removes a sprite from the batch
    @method remove
    @param sprite {Sprite} the sprite to be removed
    ###
    remove: (sprite) ->
      @size--
      if @size is 0
        sprite.batch = null
        sprite.__prev = null
        sprite.__next = null
        return
      if sprite.__prev
        sprite.__prev.__next = sprite.__next
      else
        @head = sprite.__next
        @head.__prev = null
      if sprite.__next
        sprite.__next.__prev = sprite.__prev
      else
        @tail = sprite.__prev
        @tail.__next = null
      sprite.batch = null
      sprite.__next = null
      sprite.__prev = null
      @dirty = true


    ###
    Splits the batch into two with the specified sprite being the start of the new batch.
    @method split
    @param sprite {Sprite} the sprite that indicates where the batch should be split
    @return {WebGLBatch} the new batch
    ###
    split: (sprite) ->
      
      #console.log("Splitting batch :" + this.size)
      #	console.log(sprite)
      #	console.log("-------")
      @dirty = true
      
      #var val = (this.tail == this.head)
      #console.log(val + " SAME?");
      batch = new WebGLBatch(@gl) #WebGLBatch._getBatch(this.gl);
      batch.init sprite
      batch.tail = @tail
      
      #console.log("id is " +batcheee.id)
      @tail = sprite.__prev
      @tail.__next = null
      sprite.__prev = null
      
      # return a splite batch!
      #sprite.__prev.__next = null;
      #sprite.__prev = null;
      
      # TODO this size is wrong!
      # need to recalculate :/ problem with a linked list!
      # unless it gets calculated in the "clean"?
      
      # need to loop through items as there is no way to know the length on a linked list :/
      tempSize = 0
      while sprite
        tempSize++
        sprite.batch = batch
        sprite = sprite.__next
      batch.size = tempSize
      @size -= tempSize
      batch


    ###
    Merges two batchs together
    @method merge
    @param batch {WebGLBatch} the batch that will be merged
    ###
    merge: (batch) ->
      @dirty = true
      @tail.__next = batch.head
      batch.head.__prev = @tail
      @size += batch.size
      @tail = batch.tail
      sprite = batch.head
      while sprite
        sprite.batch = this
        sprite = sprite.__next


    ###
    Grows the size of the batch. As the elements in the batch cannot have a dynamic size this function is used to increase the size of the batch. It also creates a little extra room so that the batch does not need to be resized every time a sprite is added
    @methos growBatch
    ###
    growBatch: ->
      gl = @gl
      if @size is 1
        @dynamicSize = 1
      else
        @dynamicSize = @size * 1.5
      
      # grow verts
      @verticies = new Float32Array(@dynamicSize * 8)
      gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
      gl.bufferData gl.ARRAY_BUFFER, @verticies, gl.DYNAMIC_DRAW
      @uvs = new Float32Array(@dynamicSize * 8)
      gl.bindBuffer gl.ARRAY_BUFFER, @uvBuffer
      gl.bufferData gl.ARRAY_BUFFER, @uvs, gl.DYNAMIC_DRAW
      @dirtyUVS = true
      @colors = new Float32Array(@dynamicSize * 4)
      gl.bindBuffer gl.ARRAY_BUFFER, @colorBuffer
      gl.bufferData gl.ARRAY_BUFFER, @colors, gl.DYNAMIC_DRAW
      @dirtyColors = true
      @indices = new Uint16Array(@dynamicSize * 6)
      length = @indices.length / 6
      i = 0

      while i < length
        index2 = i * 6
        index3 = i * 4
        @indices[index2 + 0] = index3 + 0
        @indices[index2 + 1] = index3 + 1
        @indices[index2 + 2] = index3 + 2
        @indices[index2 + 3] = index3 + 0
        @indices[index2 + 4] = index3 + 2
        @indices[index2 + 5] = index3 + 3
        i++
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @indexBuffer
      gl.bufferData gl.ELEMENT_ARRAY_BUFFER, @indices, gl.STATIC_DRAW


    ###
    Refresh's all the data in the batch and sync's it with the webGL buffers
    @method refresh
    ###
    refresh: ->
      gl = @gl
      @growBatch()  if @dynamicSize < @size
      indexRun = 0
      worldTransform = undefined
      width = undefined
      height = undefined
      aX = undefined
      aY = undefined
      w0 = undefined
      w1 = undefined
      h0 = undefined
      h1 = undefined
      index = undefined
      a = undefined
      b = undefined
      c = undefined
      d = undefined
      tx = undefined
      ty = undefined
      displayObject = @head
      while displayObject
        index = indexRun * 8
        texture = displayObject.texture
        frame = texture.frame
        tw = texture.baseTexture.width
        th = texture.baseTexture.height
        @uvs[index + 0] = frame.x / tw
        @uvs[index + 1] = frame.y / th
        @uvs[index + 2] = (frame.x + frame.width) / tw
        @uvs[index + 3] = frame.y / th
        @uvs[index + 4] = (frame.x + frame.width) / tw
        @uvs[index + 5] = (frame.y + frame.height) / th
        @uvs[index + 6] = frame.x / tw
        @uvs[index + 7] = (frame.y + frame.height) / th
        displayObject.updateFrame = false
        colorIndex = indexRun * 4
        @colors[colorIndex] = @colors[colorIndex + 1] = @colors[colorIndex + 2] = @colors[colorIndex + 3] = displayObject.worldAlpha
        displayObject = displayObject.__next
        indexRun++
      @dirtyUVS = true
      @dirtyColors = true


    ###
    Updates all the relevant geometry and uploads the data to the GPU
    @method update
    ###
    update: ->
      gl = @gl
      worldTransform = undefined
      width = undefined
      height = undefined
      aX = undefined
      aY = undefined
      w0 = undefined
      w1 = undefined
      h0 = undefined
      h1 = undefined
      index = undefined
      index2 = undefined
      index3 = undefined
      a = undefined
      b = undefined
      c = undefined
      d = undefined
      tx = undefined
      ty = undefined
      indexRun = 0
      displayObject = @head
      while displayObject
        width = displayObject.width
        height = displayObject.height
        aX = displayObject.anchor.x - displayObject.texture.trim.x
        aY = displayObject.anchor.y - displayObject.texture.trim.y
        w0 = width * (1 - aX)
        w1 = width * -aX
        h0 = height * (1 - aY)
        h1 = height * -aY
        index = indexRun * 8
        worldTransform = displayObject.worldTransform
        a = worldTransform[0]
        b = worldTransform[3]
        c = worldTransform[1]
        d = worldTransform[4]
        tx = worldTransform[2]
        ty = worldTransform[5]
        @verticies[index + 0] = a * w1 + c * h1 + tx
        @verticies[index + 1] = d * h1 + b * w1 + ty
        @verticies[index + 2] = a * w0 + c * h1 + tx
        @verticies[index + 3] = d * h1 + b * w0 + ty
        @verticies[index + 4] = a * w0 + c * h0 + tx
        @verticies[index + 5] = d * h0 + b * w0 + ty
        @verticies[index + 6] = a * w1 + c * h0 + tx
        @verticies[index + 7] = d * h0 + b * w1 + ty
        if displayObject.updateFrame
          @dirtyUVS = true
          texture = displayObject.texture
          frame = texture.frame
          tw = texture.baseTexture.width
          th = texture.baseTexture.height
          @uvs[index + 0] = frame.x / tw
          @uvs[index + 1] = frame.y / th
          @uvs[index + 2] = (frame.x + frame.width) / tw
          @uvs[index + 3] = frame.y / th
          @uvs[index + 4] = (frame.x + frame.width) / tw
          @uvs[index + 5] = (frame.y + frame.height) / th
          @uvs[index + 6] = frame.x / tw
          @uvs[index + 7] = (frame.y + frame.height) / th
          displayObject.updateFrame = false
        
        # TODO this probably could do with some optimisation....
        unless displayObject.cacheAlpha is displayObject.worldAlpha
          displayObject.cacheAlpha = displayObject.worldAlpha
          colorIndex = indexRun * 4
          @colors[colorIndex] = @colors[colorIndex + 1] = @colors[colorIndex + 2] = @colors[colorIndex + 3] = displayObject.worldAlpha
          @dirtyColors = true
        indexRun++
        displayObject = displayObject.__next


    ###
    Draws the batch to the frame buffer
    @method render
    ###
    render: ->
      if @dirty
        @refresh()
        @dirty = false
      return  if @size is 0
      @update()
      gl = @gl
      
      #TODO optimize this!
      if @blendMode is Sprite.blendModes.NORMAL
        gl.blendFunc gl.ONE, gl.ONE_MINUS_SRC_ALPHA
      else
        gl.blendFunc gl.ONE, gl.ONE_MINUS_SRC_COLOR
      shaderProgram = WebGLShaders.shaderProgram
      
      # update the verts..
      gl.bindBuffer gl.ARRAY_BUFFER, @vertexBuffer
      
      # ok..
      gl.bufferSubData gl.ARRAY_BUFFER, 0, @verticies
      gl.vertexAttribPointer shaderProgram.vertexPositionAttribute, 2, gl.FLOAT, false, 0, 0
      
      # update the uvs
      gl.bindBuffer gl.ARRAY_BUFFER, @uvBuffer
      if @dirtyUVS
        @dirtyUVS = false
        gl.bufferSubData gl.ARRAY_BUFFER, 0, @uvs
      gl.vertexAttribPointer shaderProgram.textureCoordAttribute, 2, gl.FLOAT, false, 0, 0
      gl.activeTexture gl.TEXTURE0
      gl.bindTexture gl.TEXTURE_2D, @texture._glTexture
      
      # update color!
      gl.bindBuffer gl.ARRAY_BUFFER, @colorBuffer
      if @dirtyColors
        @dirtyColors = false
        gl.bufferSubData gl.ARRAY_BUFFER, 0, @colors
      gl.vertexAttribPointer shaderProgram.colorAttribute, 1, gl.FLOAT, false, 0, 0
      
      # dont need to upload!
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @indexBuffer
      
      # DRAW THAT this!
      gl.drawElements gl.TRIANGLES, @size * 6, gl.UNSIGNED_SHORT, 0

  return WebGLBatch