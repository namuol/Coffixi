###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/display/DisplayObject', [
  'Coffixi/core/Matrix'
  'Coffixi/utils/Module'
], (
  Matrix
  Module  
) ->

  ###
  this is the base class for all objects that are rendered on the screen.
  @class DisplayObject
  @constructor
  ###
  class DisplayObject extends Module
    constructor: ->
      ###
      The x coordinate of the object relative to the local coordinates of the parent.
      @property x
      ###
      @x = 0

      ###
      The y coordinate of the object relative to the local coordinates of the parent.
      @property y
      ###
      @y = 0
      
      ###
      The X scale factor of the object.
      @property scaleX
      ###
      @scaleX = 1

      ###
      The Y scale factor of the object.
      @property scaleY
      ###
      @scaleY = 1
      
      ###
      The x coordinate of the pivot point that this displayObject rotates around
      @property pivotX
      ###
      @pivotX = 0

      ###
      The x coordinate of the pivot point that this displayObject rotates around
      @property pivotX
      ###
      @pivotY = 0

      ###
      The rotation of the object in radians.
      @property rotation
      @type Number
      ###
      @rotation = 0
      
      ###
      The opacity of the object.
      @property alpha
      @type Number
      ###
      @alpha = 1
      
      ###
      The visibility of the object.
      @property visible
      @type Boolean
      ###
      @visible = true
      @worldVisible = false
      
      ###
      [read-only] The display object container that contains this display object.
      @property parent
      @type DisplayObjectContainer
      ###
      @parent = null
      
      ###
      [read-only] The stage the display object is connected to, or undefined if it is not connected to the stage.
      @property stage
      @type Stage
      ###
      @stage ?= null
      
      ###
      This is the defined area that will pick up mouse / touch events. It is null by default.
      Setting it is a neat way of optimising the hitTest function that the interactionManager will use (as it will not need to hit test all the children)
      @property hitArea
      @type Rectangle
      ###
      @hitArea = null
      @worldAlpha = 1
      @color = []
      @worldTransform = Matrix.mat3.create() #mat3.identity();
      @localTransform = Matrix.mat3.create() #mat3.identity();
      @dynamic = true
      
      # chach that puppy!
      @_sr = 0
      @_cr = 1
      @childIndex = 0
      @renderable = false

    #TODO make visible a getter setter
    #
    #Object.defineProperty(PIXI.DisplayObject.prototype, 'visible', {
    #    get: function() {
    #        return this._visible;
    #    },
    #    set: function(value) {
    #        this._visible = value;
    #    }
    #});

    ###
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
      
      #/AAARR GETTER SETTTER!
      #localTransform[2] = this.x;
      #localTransform[5] = this.y;
      px = @pivotX
      py = @pivotY
      
      #/AAARR GETTER SETTTER!
      localTransform[2] = @x - localTransform[0] * px - py * localTransform[1]
      localTransform[5] = @y - localTransform[4] * py - px * localTransform[3]
      
      # Cache the matrix values (makes for huge speed increases!)
      a00 = localTransform[0]
      a01 = localTransform[1]
      a02 = localTransform[2]
      a10 = localTransform[3]
      a11 = localTransform[4]
      a12 = localTransform[5]
      b00 = parentTransform[0]
      b01 = parentTransform[1]
      b02 = parentTransform[2]
      b10 = parentTransform[3]
      b11 = parentTransform[4]
      b12 = parentTransform[5]
      worldTransform[0] = b00 * a00 + b01 * a10
      worldTransform[1] = b00 * a01 + b01 * a11
      worldTransform[2] = b00 * a02 + b01 * a12 + b02
      worldTransform[3] = b10 * a00 + b11 * a10
      worldTransform[4] = b10 * a01 + b11 * a11
      worldTransform[5] = b10 * a02 + b11 * a12 + b12
      
      # because we are using affine transformation, we can optimise the matrix concatenation process.. wooo!
      # mat3.multiply(this.localTransform, this.parent.worldTransform, this.worldTransform);
      @worldAlpha = @alpha * @parent.worldAlpha