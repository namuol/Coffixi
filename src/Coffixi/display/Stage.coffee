###
@author Mat Groves http://matgroves.com/ @Doormat23
###

define 'Coffixi/display/Stage', [
  './DisplayObjectContainer'
  'Coffixi/core/Point'
  'Coffixi/textures/Texture'
  'Coffixi/core/Matrix'
  'Coffixi/utils/Utils'
], (
  DisplayObjectContainer
  Point
  Texture
  Matrix
  Utils
) ->

  ###
  A Stage represents the root of the display tree. Everything connected to the stage is rendered

  @class Stage
  @extends DisplayObjectContainer
  @constructor
  @param backgroundColor {Number} the background color of the stage, easiest way to pass this in is in hex format
  like: 0xFFFFFF for white
  ###
  class Stage extends DisplayObjectContainer
    constructor: (backgroundColor) ->
      super
      
      ###
      [read-only] Current transform of the object based on world (parent) factors
      
      @property worldTransform
      @type Mat3
      @readOnly
      @private
      ###
      @worldTransform = Matrix.mat3.create()
      
      ###
      Whether the stage is dirty and needs to be updated
      
      @property dirty
      @type Boolean
      @private
      ###
      @dirty = true
      @__childrenAdded = []
      @__childrenRemoved = []
      
      #the stage is it's own stage
      @stage = this

      @setBackgroundColor backgroundColor
      @worldVisible = true

    #
    # * Updates the object transform for rendering
    # *
    # * @method updateTransform
    # * @private
    # 
    updateTransform: ->
      @worldAlpha = 1
      i = 0
      j = @children.length

      while i < j
        @children[i].updateTransform()
        i++

      if @dirty
        @dirty = false

    ###
    Sets the background color for the stage

    @method setBackgroundColor
    @param backgroundColor {Number} the color of the background, easiest way to pass this in is in hex format
    like: 0xFFFFFF for white
    ###
    setBackgroundColor: (backgroundColor) ->
      @backgroundColor = backgroundColor or 0x000000
      @backgroundColorSplit = Utils.HEXtoRGB(@backgroundColor)
      hex = @backgroundColor.toString(16)
      hex = "000000".substr(0, 6 - hex.length) + hex
      @backgroundColorString = "#" + hex