###*
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/display/DisplayObject', [
  'Coffixi/core/Point'
  'Coffixi/core/Matrix'
  'Coffixi/filters/FilterBlock'
  'Coffixi/utils/Module'
], (
  Point
  Matrix
  FilterBlock
  Module
) ->

  ###*
  The base class for all objects that are rendered on the screen.

  @class DisplayObject
  @constructor
  ###
  class DisplayObject extends Module
    constructor: ->
      @last = this
      @first = this
      
      ###*
      The x coordinate of the object relative to the local coordinates of the parent.
      @property x
      ###
      @x = 0

      ###*
      The y coordinate of the object relative to the local coordinates of the parent.
      @property y
      ###
      @y = 0
      
      ###*
      The X scale factor of the object.
      @property scaleX
      ###
      @scaleX = 1

      ###*
      The Y scale factor of the object.
      @property scaleY
      ###
      @scaleY = 1
      
      ###*
      The x coordinate of the pivot point that this displayObject rotates around
      @property pivotX
      ###
      @pivotX = 0

      ###*
      The x coordinate of the pivot point that this displayObject rotates around
      @property pivotX
      ###
      @pivotY = 0
      
      ###*
      The rotation of the object in radians.
      
      @property rotation
      @type Number
      ###
      @rotation = 0
      
      ###*
      The opacity of the object.
      
      @property alpha
      @type Number
      ###
      @alpha = 1
      
      ###*
      The visibility of the object.
      
      @property visible
      @type Boolean
      ###
      @visible = true
      
      ###*
      This is used to indicate if the displayObject should display a mouse hand cursor on rollover
      
      @property buttonMode
      @type Boolean
      ###
      @buttonMode = false
      
      ###*
      Can this object be rendered
      
      @property renderable
      @type Boolean
      ###
      @renderable = false
      
      ###*
      The visibility of the object based on world (parent) factors.
      
      @property worldVisible
      @type Boolean
      @final
      ###
      @worldVisible = false
      
      ###*
      The display object container that contains this display object.
      
      @property parent
      @type DisplayObjectContainer
      @final
      ###
      @parent = null
      
      ###*
      The stage the display object is connected to, or undefined if it is not connected to the stage.
      
      @property stage
      @type Stage
      @final
      ###
      @stage ?= null
      
      ###*
      The multiplied alpha of the displayobject
      
      @property worldAlpha
      @type Number
      @final
      ###
      @worldAlpha = 1
            
      ###*
      Current transform of the object based on world (parent) factors
      
      @property worldTransform
      @type Mat3
      @final
      @private
      ###
      @worldTransform = Matrix.mat3.create() #mat3.identity();
      
      ###*
      Current transform of the object locally
      
      @property localTransform
      @type Mat3
      @final
      @private
      ###
      @localTransform = Matrix.mat3.create() #mat3.identity();
      
      # chach that puppy!
      @_sr = 0
      @_cr = 1

    ###*
    Sets a mask for the displayObject. A mask is an object that limits the visibility of an object to the shape of the mask applied to it.
    A regular mask must be a Graphics object. This allows for much faster masking in canvas as it utilises shape clipping.
    To remove a mask, set this property to null.

    @property mask
    @type Graphics
    ###
    Object.defineProperty DisplayObject::, "mask",
      get: ->
        @_mask

      set: (value) ->
        @_mask = value
        if value
          @addFilter value
        else
          @removeFilter()

    ###*
    Adds a filter to this displayObject

    @method addFilter
    @param mask {Graphics} the graphics object to use as a filter
    @private
    ###
    addFilter: (mask) ->
      return  if @filter
      @filter = true
      
      # insert a filter block..
      start = new FilterBlock()
      end = new FilterBlock()
      start.mask = mask
      end.mask = mask
      start.first = start.last = this
      end.first = end.last = this
      start.open = true
      
      #	insert start
      childFirst = start
      childLast = start
      nextObject = undefined
      previousObject = undefined
      previousObject = @first._iPrev
      if previousObject
        nextObject = previousObject._iNext
        childFirst._iPrev = previousObject
        previousObject._iNext = childFirst
      else
        nextObject = this
      if nextObject
        nextObject._iPrev = childLast
        childLast._iNext = nextObject
      
      # now insert the end filter block..
      
      #	insert end filter
      childFirst = end
      childLast = end
      nextObject = null
      previousObject = null
      previousObject = @last
      nextObject = previousObject._iNext
      if nextObject
        nextObject._iPrev = childLast
        childLast._iNext = nextObject
      childFirst._iPrev = previousObject
      previousObject._iNext = childFirst
      updateLast = this
      prevLast = @last
      while updateLast
        updateLast.last = end  if updateLast.last is prevLast
        updateLast = updateLast.parent
      @first = start
      
      # if webGL...
      @__renderGroup.addFilterBlocks start, end  if @__renderGroup
      mask.renderable = false

    ###*
    Removes the filter to this displayObject
    
    @method removeFilter
    @private
    ###
    removeFilter: ->
      return  unless @filter
      @filter = false
      
      # modify the list..
      startBlock = @first
      nextObject = startBlock._iNext
      previousObject = startBlock._iPrev
      nextObject._iPrev = previousObject  if nextObject
      previousObject._iNext = nextObject  if previousObject
      @first = startBlock._iNext
      
      # remove the end filter
      lastBlock = @last
      nextObject = lastBlock._iNext
      previousObject = lastBlock._iPrev
      nextObject._iPrev = previousObject  if nextObject
      previousObject._iNext = nextObject
      
      # this is always true too!
      #	if(this.last == lastBlock)
      #{
      tempLast = lastBlock._iPrev
      
      # need to make sure the parents last is updated too
      updateLast = this
      while updateLast.last is lastBlock
        updateLast.last = tempLast
        updateLast = updateLast.parent
        break  unless updateLast
      mask = startBlock.mask
      mask.renderable = true
      
      # if webGL...
      @__renderGroup.removeFilterBlocks startBlock, lastBlock  if @__renderGroup

    ###*
    Updates the object transform for rendering
    
    @method updateTransform
    @private
    ###
    updateTransform: ->
      
      # TODO OPTIMIZE THIS!! with dirty
      unless @rotation is @rotationCache
        @rotationCache = @rotation
        @_sr = Math.sin(@rotation)
        @_cr = Math.cos(@rotation)
      localTransform = @localTransform
      parentTransform = @parent.worldTransform
      worldTransform = @worldTransform
      
      #console.log(localTransform)
      localTransform[0] = @_cr * @scaleX
      localTransform[1] = -@_sr * @scaleY
      localTransform[3] = @_sr * @scaleX
      localTransform[4] = @_cr * @scaleY
      
      # TODO --> do we even need a local matrix???
      px = @pivotX
      py = @pivotY
      
      # Cache the matrix values (makes for huge speed increases!)
      a00 = localTransform[0]
      a01 = localTransform[1]
      a02 = @x - localTransform[0] * px - py * localTransform[1]
      a10 = localTransform[3]
      a11 = localTransform[4]
      a12 = @y - localTransform[4] * py - px * localTransform[3]
      b00 = parentTransform[0]
      b01 = parentTransform[1]
      b02 = parentTransform[2]
      b10 = parentTransform[3]
      b11 = parentTransform[4]
      b12 = parentTransform[5]
      localTransform[2] = a02
      localTransform[5] = a12
      worldTransform[0] = b00 * a00 + b01 * a10
      worldTransform[1] = b00 * a01 + b01 * a11
      worldTransform[2] = b00 * a02 + b01 * a12 + b02
      worldTransform[3] = b10 * a00 + b11 * a10
      worldTransform[4] = b10 * a01 + b11 * a11
      worldTransform[5] = b10 * a02 + b11 * a12 + b12
      
      # because we are using affine transformation, we can optimise the matrix concatenation process.. wooo!
      # mat3.multiply(this.localTransform, this.parent.worldTransform, this.worldTransform);
      @worldAlpha = @alpha * @parent.worldAlpha

    getGlobalX: ->
      @updateTransform()
      @worldTransform[2]
    getGlobalY: ->
      @updateTransform()
      @worldTransform[5]

    getChildIndex: -> @parent?.children.indexOf @ ? NaN
    getTreeDepth: ->
      return 0  if not @parent?
      return 1 + @parent.getTreeDepth()

    isAbove: (other) ->
      a = @
      b = other

      otherDepth = other.getTreeDepth()
      depth = @getTreeDepth()

      loop
        return true  if a.parent is b
        return false  if b.parent is a

        break  if (a.parent is b.parent) or (not a.parent?) or (not b.parent?)

        if depth > otherDepth
          a = a.parent
          depth -= 1
        else if otherDepth > depth
          b = b.parent
          otherDepth -= 1
        else
          a = a.parent
          b = b.parent

      return a.getChildIndex() > b.getChildIndex()